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
  bool _isLoading = false;
  String _error = '';
  bool _isPremiumUser = false; // Track premium status

  // Getters
  List<ProductDetails> get products => _products;
  bool get isStoreAvailable => _isStoreAvailable;
  bool get isLoading => _isLoading;
  String get error => _error;
  bool get isPremiumUser => _isPremiumUser;

  // Get dependencies from locator
  SubscriptionProvider()
    : _client = locator<http.Client>(),
      // Define baseUrl consistently using environment variable or default
      _baseUrl = const String.fromEnvironment(
        'BACKEND_URL',
        defaultValue: 'http://localhost:8000',
      ) {
    final Stream<List<PurchaseDetails>> purchaseUpdated = _iap.purchaseStream;
    _purchaseSubscription = purchaseUpdated.listen(
      _onPurchaseUpdate,
      onDone: () => _purchaseSubscription.cancel(),
      onError: (error) {
        print("Error listening to purchase stream: $error");
        _setError('Failed to listen for purchase updates.');
      },
    );
    initialize();
  }

  @override
  void dispose() {
    _purchaseSubscription.cancel();
    super.dispose();
  }

  // Public method to initialize or retry initialization
  Future<void> initialize() async {
    _setLoading(true);
    _isStoreAvailable = await _iap.isAvailable();
    print("InAppPurchase store available: $_isStoreAvailable");

    if (_isStoreAvailable) {
      await _loadProducts();
      await restorePurchases(); // Call public method
    } else {
      _setError('The store is not available on this device.');
    }
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
    notifyListeners();
  }

  // Public method to restore previous purchases
  Future<void> restorePurchases() async {
    try {
      await _iap.restorePurchases();
      print("Attempted to restore purchases.");
      // The purchase stream (_onPurchaseUpdate) will handle the restored purchases.
      // We might need a slight delay or check after restore if the stream doesn't fire immediately.
    } catch (e) {
      print("Error restoring purchases: $e");
      _setError('Failed to restore previous purchases.');
    }
  }

  Future<void> _onPurchaseUpdate(
    List<PurchaseDetails> purchaseDetailsList,
  ) async {
    print("Purchase update received: ${purchaseDetailsList.length} items");
    for (var purchaseDetails in purchaseDetailsList) {
      await _handlePurchase(purchaseDetails);
    }
    _updatePremiumStatus(); // Update status after handling all updates
    notifyListeners();
  }

  Future<void> _handlePurchase(PurchaseDetails purchaseDetails) async {
    print(
      "Handling purchase: ${purchaseDetails.productID}, Status: ${purchaseDetails.status}",
    );
    if (purchaseDetails.status == PurchaseStatus.purchased ||
        purchaseDetails.status == PurchaseStatus.restored) {
      // --- Backend Validation Step ---
      bool isValid = await _validatePurchaseWithBackend(purchaseDetails);

      if (isValid) {
        print("Backend validation successful for ${purchaseDetails.productID}");
        // Add to local list if not already there (based on purchaseID)
        // Only add if validation passed
        if (!_purchases.any(
          (p) => p.purchaseID == purchaseDetails.purchaseID,
        )) {
          _purchases.add(purchaseDetails);
        }
        _updatePremiumStatus(); // Update premium status based on validated purchase

        if (purchaseDetails.pendingCompletePurchase) {
          // IMPORTANT: Complete the purchase ONLY after successful backend validation
          await _iap.completePurchase(purchaseDetails);
          print("Purchase completed via IAP for ${purchaseDetails.purchaseID}");
        }
      } else {
        print("Backend validation failed for ${purchaseDetails.productID}");
        _setError('فشلت عملية التحقق من الشراء.');
        // Do NOT complete the purchase if backend validation fails
        // Remove from local list if it was added optimistically before validation
        _purchases.removeWhere(
          (p) => p.purchaseID == purchaseDetails.purchaseID,
        );
        _updatePremiumStatus(); // Update premium status (likely to false)
      }
      // --- End Backend Validation Step ---
    } else if (purchaseDetails.status == PurchaseStatus.error) {
      print("Purchase error: ${purchaseDetails.error}");
      _setError(
        'Purchase failed: ${purchaseDetails.error?.message ?? 'Unknown error'}',
      );
    } else if (purchaseDetails.status == PurchaseStatus.canceled) {
      print("Purchase canceled for ${purchaseDetails.productID}");
      // Optionally show a message to the user
    } else if (purchaseDetails.status == PurchaseStatus.pending) {
      print("Purchase pending for ${purchaseDetails.productID}");
      // Inform the user that the purchase is pending
    }

    // Update internal list based on latest status (remove canceled/error?)
    // This logic might need refinement based on how you want to handle non-active purchases.
    _purchases.removeWhere(
      (p) =>
          p.purchaseID == purchaseDetails.purchaseID &&
          (p.status == PurchaseStatus.canceled ||
              p.status == PurchaseStatus.error),
    );
  }

  // Update the _isPremiumUser flag based on *validated* active purchases
  // This method now primarily reflects the state derived from validated purchases
  void _updatePremiumStatus() {
    final bool wasPremium = _isPremiumUser;

    // Check validated purchases list for the premium product ID
    // Note: We rely on _handlePurchase to add/remove items from _purchases
    // based on backend validation result.
    _isPremiumUser = _purchases.any(
      (purchase) =>
          purchase.productID == _premiumMonthlyProductId &&
          (purchase.status == PurchaseStatus.purchased ||
              purchase.status == PurchaseStatus.restored),
      // We implicitly trust items in _purchases are validated by _handlePurchase
    );

    if (wasPremium != _isPremiumUser) {
      print(
        "Premium status updated based on validated purchases: $_isPremiumUser",
      );
      notifyListeners();
    }
  }

  // --- Backend Validation Method ---
  Future<bool> _validatePurchaseWithBackend(
    PurchaseDetails purchaseDetails,
  ) async {
    final url = Uri.parse('$_baseUrl/api/v1/subscriptions/validate/');
    final verificationData = purchaseDetails.verificationData;
    final serverVerificationData = verificationData.serverVerificationData;
    final source = verificationData.source; // e.g., 'google_play', 'app_store'

    // Determine platform string
    String platform;
    if (Platform.isAndroid) {
      platform = 'android';
    } else if (Platform.isIOS) {
      platform = 'ios';
    } else {
      print(
        "Unsupported platform for purchase validation: ${Platform.operatingSystem}",
      );
      return false; // Cannot validate on unsupported platforms
    }

    // Ensure we have the necessary data
    if (serverVerificationData.isEmpty) {
      print("Missing serverVerificationData for validation.");
      // For restored purchases, serverVerificationData might be empty initially.
      // Need to handle restoration flow properly, maybe trigger refresh?
      // For now, treat as invalid if token is missing.
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
          .timeout(
            const Duration(seconds: 20),
          ); // Longer timeout for validation

      print("Backend validation response: ${response.statusCode}");
      if (response.statusCode == 200) {
        final responseBody = json.decode(response.body) as Map<String, dynamic>;
        // Update status based on backend response (more reliable)
        final bool backendPremiumStatus =
            responseBody['is_premium'] as bool? ?? false;
        // TODO: Potentially store expiry date from responseBody['expiry_date']
        _isPremiumUser =
            backendPremiumStatus; // Directly set status from backend
        print("Backend validation successful. Premium: $_isPremiumUser");
        return true; // Indicate validation was successful
      } else {
        print(
          "Backend validation failed: ${response.statusCode} - ${response.body}",
        );
        _isPremiumUser = false; // Assume not premium if validation fails
        return false;
      }
    } catch (e) {
      print("Error during backend validation request: $e");
      _isPremiumUser = false; // Assume not premium on error
      _setError("Failed to connect to validation server.");
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
      // For non-consumable or subscriptions, always false. For consumable true.
      final bool success = await _iap.buyNonConsumable(
        purchaseParam: purchaseParam,
      );
      print("Initiating purchase result: $success");
      // The result (success/failure/pending) will come through the purchase stream (_onPurchaseUpdate)
    } catch (e) {
      print("Error initiating purchase: $e");
      _setError('Failed to initiate purchase.');
    } finally {
      _setLoading(false); // Loading finished when buyNonConsumable returns
    }
  }

  // Helper methods for state management
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String message) {
    _error = message;
    notifyListeners();
  }
}
