import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  InterstitialAd? _interstitialAd;
  int _interstitialLoadAttempts = 0;
  final int maxFailedLoadAttempts = 3; // Prevent infinite retry loops

  // Counter for triggering interstitial ads
  int _usageCounter = 0;
  final int _showAdFrequency = 10; // Show ad every 10 uses

  // Use test ad unit IDs
  final String _interstitialAdUnitId =
      Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/1033173712' // Android Test ID
          : 'ca-app-pub-3940256099942544/4411468910'; // iOS Test ID

  AdService() {
    _loadInterstitialAd(); // Load an ad initially
  }

  void _loadInterstitialAd() {
    if (_interstitialLoadAttempts >= maxFailedLoadAttempts) {
      print('AdService: Max interstitial failed load attempts reached.');
      return;
    }

    InterstitialAd.load(
      adUnitId: _interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          print('InterstitialAd loaded.');
          _interstitialAd = ad;
          _interstitialLoadAttempts = 0; // Reset attempts on success
          _setupFullScreenContentCallback(); // Setup callbacks after loading
        },
        onAdFailedToLoad: (LoadAdError error) {
          print('InterstitialAd failed to load: $error');
          _interstitialLoadAttempts++;
          _interstitialAd = null; // Ensure ad is null on failure
          // Optionally retry loading after a delay
          // Future.delayed(Duration(seconds: 60), () => _loadInterstitialAd());
        },
      ),
    );
  }

  void _setupFullScreenContentCallback() {
    if (_interstitialAd == null) return;

    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent:
          (InterstitialAd ad) =>
              print('InterstitialAd showed full screen content.'),
      onAdDismissedFullScreenContent: (InterstitialAd ad) {
        print('InterstitialAd dismissed full screen content.');
        ad.dispose(); // Dispose the ad after it's shown
        _interstitialAd = null; // Clear the ad reference
        _loadInterstitialAd(); // Load the next ad
      },
      onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
        print('InterstitialAd failed to show full screen content: $error');
        ad.dispose();
        _interstitialAd = null;
        _loadInterstitialAd(); // Try loading again
      },
      onAdImpression:
          (InterstitialAd ad) => print('InterstitialAd impression.'),
    );
  }

  // Call this method when a feature is used (e.g., search, view details)
  void incrementUsageCounterAndShowAdIfNeeded() {
    _usageCounter++;
    print('AdService: Usage counter incremented to $_usageCounter');
    if (_usageCounter >= _showAdFrequency) {
      showInterstitialAd();
      _usageCounter = 0; // Reset counter after showing (or attempting to show)
    }
  }

  // Call this method to explicitly show the ad
  void showInterstitialAd() {
    if (_interstitialAd != null) {
      print('AdService: Attempting to show InterstitialAd.');
      _interstitialAd!.show();
      // Callbacks in _setupFullScreenContentCallback handle disposal and reloading
    } else {
      print('AdService: InterstitialAd not ready yet.');
      // Optionally try loading again if it's null
      if (_interstitialLoadAttempts < maxFailedLoadAttempts) {
        print('AdService: Triggering ad load.');
        _loadInterstitialAd();
      }
    }
  }

  // Dispose method if the service needs cleanup (e.g., in a Provider dispose)
  void dispose() {
    _interstitialAd?.dispose();
    print('AdService disposed.');
  }
}
