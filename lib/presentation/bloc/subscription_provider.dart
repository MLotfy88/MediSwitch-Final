import 'dart:async';
import 'dart:convert'; // For jsonEncode
import 'dart:io'; // For Platform check
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http; // Import http
import 'package:in_app_purchase/in_app_purchase.dart';
import '../../data/datasources/remote/config_remote_data_source.dart'; // Import ConfigRemoteDataSource
import '../../core/di/locator.dart'; // Import locator to get dependencies

// Define product IDs (replace with your actual IDs from App Store Connect / Google Play Console)
const String _premiumMonthlyProductId =
    'mediswitch_premium_monthly'; // Example ID
const Set<String> _productIds = {_premiumMonthlyProductId};

class SubscriptionProvider extends ChangeNotifier {
  final InAppPurchase _iap = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _purchaseSubscription;
  final http.Client _client; // HTTP client for backend validation
  final String _baseUrl; // Backend base URL

  // State variables
  List<ProductDetails> _products = []; // Available products/subscriptions
  List<PurchaseDetails> _purchases = []; // Active purchases/subscriptions
  bool _isStoreAvailable = false;
  bool _isLoading =
      false; // Tracks loading state for initialization and purchases
  String _error = '';
  bool _isPremiumUser = false; // Track premium status
  bool _isInitialized = false; // Add initialized flag

  // Getters
  List<ProductDetails> get products => _products;
  bool get isStoreAvailable => _isStoreAvailable;
  bool get isLoading => _isLoading;
  String get error => _error;
  bool get isPremiumUser => _isPremiumUser;
  bool get isInitialized => _isInitialized; // Expose getter

  // Get dependencies from locator
  SubscriptionProvider()
    : _client = locator<http.Client>(),
      _baseUrl = const String.fromEnvironment(
        'BACKEND_URL',
        defaultValue: 'http://localhost:8000',
      ) {
    // Initialize purchase stream listener immediately
    final Stream<List<PurchaseDetails>> purchaseUpdated = _iap.purchaseStream;
    _purchaseSubscription = purchaseUpdated.listen(
      _onPurchaseUpdate,
      onDone: () => _purchaseSubscription.cancel(),
      onError: (error) {
        print("Error listening to purchase stream: $error");
        _setError('Failed to listen for purchase updates.');
      },
    );
    // Don't call initialize immediately, call it externally or lazily
    // initialize();
  }

  @override
  void dispose() {
    _purchaseSubscription.cancel();
    super.dispose();
  }

  // Public method to initialize or retry initialization
  Future<void> initialize() async {
    if (_isInitialized) return; // Don't re-initialize if already done
    if (_isLoading) return; // Prevent concurrent initialization

    _setLoading(true);
    _error = ''; // Clear previous errors on init
    _isStoreAvailable = await _iap.isAvailable();
    print("InAppPurchase store available: $_isStoreAvailable");

    if (_isStoreAvailable) {
      await _loadProducts();
      await restorePurchases(); // Call public method
    } else {
      _setError('The store is not available on this device.');
    }
    _isInitialized =
        true; // Mark as initialized even if store is unavailable or error occurred
    _setLoading(false);
  }

  Future<void> _loadProducts() async {
    try {
      final ProductDetailsResponse response = await _iap.queryProductDetails(
        _productIds,
      );
      if (response.error != null) {
        print("Error loading products: ${response.error}");
        _setError(
          'Failed to load subscription products: ${response.error!.message}',
        );
        _products = [];
      } else {
        _products = response.productDetails;
        print("Loaded products: ${_products.map((p) => p.id).join(', ')}");
      }
    } catch (e) {
      print("Exception loading products: $e");
      _setError('An unexpected error occurred while loading products.');
      _products = [];
    }
    // No notifyListeners here, initialize() handles it at the end
  }

  // Public method to restore previous purchases
  Future<void> restorePurchases() async {
    if (!_isStoreAvailable) return; // Don't attempt if store is unavailable
    try {
      await _iap.restorePurchases();
      print("Attempted to restore purchases.");
      // The purchase stream (_onPurchaseUpdate) will handle the restored purchases.
    } catch (e) {
      print("Error restoring purchases: $e");
      _setError('Failed to restore previous purchases.');
      // No notifyListeners here, initialize() handles it at the end
    }
  }

  Future<void> _onPurchaseUpdate(
    List<PurchaseDetails> purchaseDetailsList,
  ) async {
    print("Purchase update received: ${purchaseDetailsList.length} items");
    // Use a temporary loading state specific to purchase handling?
    // Or rely on the global isLoading flag if purchase initiation sets it.
    bool needsNotify = false;
    for (var purchaseDetails in purchaseDetailsList) {
      final changed = await _handlePurchase(purchaseDetails);
      if (changed) needsNotify = true;
    }
    // Update premium status after handling all updates in the batch
    final premiumChanged = _updatePremiumStatus();
    if (needsNotify || premiumChanged) {
      notifyListeners();
    }
  }

  // Returns true if state changed that requires notification
  Future<bool> _handlePurchase(PurchaseDetails purchaseDetails) async {
    bool stateChanged = false;
    print(
      "Handling purchase: ${purchaseDetails.productID}, Status: ${purchaseDetails.status}",
    );
    if (purchaseDetails.status == PurchaseStatus.purchased ||
        purchaseDetails.status == PurchaseStatus.restored) {
      bool isValid = await _validatePurchaseWithBackend(purchaseDetails);
      if (isValid) {
        print("Backend validation successful for ${purchaseDetails.productID}");
        if (!_purchases.any(
          (p) => p.purchaseID == purchaseDetails.purchaseID,
        )) {
          _purchases.add(purchaseDetails);
          stateChanged = true; // Added a purchase
        }
        if (purchaseDetails.pendingCompletePurchase) {
          await _iap.completePurchase(purchaseDetails);
          print("Purchase completed via IAP for ${purchaseDetails.purchaseID}");
        }
      } else {
        print("Backend validation failed for ${purchaseDetails.productID}");
        _setError('فشلت عملية التحقق من الشراء.');
        stateChanged = true; // Error state changed
        // Remove from local list if it was added optimistically
        final initialLength = _purchases.length;
        _purchases.removeWhere(
          (p) => p.purchaseID == purchaseDetails.purchaseID,
        );
        if (_purchases.length < initialLength)
          stateChanged = true; // Check if length changed
      }
    } else if (purchaseDetails.status == PurchaseStatus.error) {
      print("Purchase error: ${purchaseDetails.error}");
      _setError(
        'Purchase failed: ${purchaseDetails.error?.message ?? 'Unknown error'}',
      );
      stateChanged = true; // Error state changed
    } else if (purchaseDetails.status == PurchaseStatus.canceled) {
      print("Purchase canceled for ${purchaseDetails.productID}");
      // Optionally show a message to the user or just update state
    } else if (purchaseDetails.status == PurchaseStatus.pending) {
      print("Purchase pending for ${purchaseDetails.productID}");
      // Optionally update UI to show pending state
    }

    // Update internal list based on latest status (remove canceled/error?)
    final initialLengthBeforeRemove = _purchases.length;
    _purchases.removeWhere(
      (p) =>
          p.purchaseID == purchaseDetails.purchaseID &&
          (p.status == PurchaseStatus.canceled ||
              p.status == PurchaseStatus.error),
    );
    if (_purchases.length < initialLengthBeforeRemove)
      stateChanged = true; // Check if length changed

    return stateChanged;
  }

  // Update the _isPremiumUser flag based on *validated* active purchases
  // Returns true if the premium status actually changed
  bool _updatePremiumStatus() {
    final bool wasPremium = _isPremiumUser;
    _isPremiumUser = _purchases.any(
      (purchase) =>
          purchase.productID == _premiumMonthlyProductId &&
          (purchase.status == PurchaseStatus.purchased ||
              purchase.status == PurchaseStatus.restored),
    );

    if (wasPremium != _isPremiumUser) {
      print(
        "Premium status updated based on validated purchases: $_isPremiumUser",
      );
      return true; // Status changed
    }
    return false; // Status did not change
  }

  // --- Backend Validation Method ---
  Future<bool> _validatePurchaseWithBackend(
    PurchaseDetails purchaseDetails,
  ) async {
    final url = Uri.parse('$_baseUrl/api/v1/subscriptions/validate/');
    final verificationData = purchaseDetails.verificationData;
    final serverVerificationData = verificationData.serverVerificationData;
    final source = verificationData.source;

    String platform;
    if (Platform.isAndroid) {
      platform = 'android';
    } else if (Platform.isIOS) {
      platform = 'ios';
    } else {
      print(
        "Unsupported platform for purchase validation: ${Platform.operatingSystem}",
      );
      return false;
    }

    if (serverVerificationData.isEmpty) {
      print("Missing serverVerificationData for validation.");
      return false;
    }

    print("Sending validation request to backend...");
    try {
      final response = await _client
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'platform': platform,
              'purchase_token': serverVerificationData,
              'product_id': purchaseDetails.productID,
              // TODO: Send user/device identifier if needed by backend
            }),
          )
          .timeout(const Duration(seconds: 20));

      print("Backend validation response: ${response.statusCode}");
      if (response.statusCode == 200) {
        final responseBody = json.decode(response.body) as Map<String, dynamic>;
        final bool backendPremiumStatus =
            responseBody['is_premium'] as bool? ?? false;
        // Don't directly set _isPremiumUser here, let _updatePremiumStatus handle it
        // based on the validated _purchases list.
        print(
          "Backend validation successful. Backend says premium: $backendPremiumStatus",
        );
        return true; // Indicate validation was successful (backend processed it)
      } else {
        print(
          "Backend validation failed: ${response.statusCode} - ${response.body}",
        );
        return false;
      }
    } catch (e) {
      print("Error during backend validation request: $e");
      _setError("Failed to connect to validation server.");
      // notifyListeners(); // Notify about the error
      return false;
    }
  }

  // Method to initiate a purchase
  Future<void> purchaseSubscription(ProductDetails productDetails) async {
    if (!_isStoreAvailable) {
      _setError('Store is not available.');
      notifyListeners();
      return;
    }
    if (_isLoading) return; // Prevent multiple purchase attempts

    _setLoading(true);
    _setError(''); // Clear previous error

    final PurchaseParam purchaseParam = PurchaseParam(
      productDetails: productDetails,
    );

    try {
      // For subscriptions, use buyNonConsumable
      final bool success = await _iap.buyNonConsumable(
        purchaseParam: purchaseParam,
      );
      print("Initiating purchase result: $success");
      // Result comes via the stream
    } catch (e) {
      print("Error initiating purchase: $e");
      _setError('Failed to initiate purchase.');
    } finally {
      _setLoading(false); // Loading finished when buyNonConsumable returns
    }
  }

  // Helper methods for state management
  void _setLoading(bool value) {
    if (_isLoading == value) return; // Avoid unnecessary notifications
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String message) {
    if (_error == message) return; // Avoid unnecessary notifications
    _error = message;
    notifyListeners();
  }
}
