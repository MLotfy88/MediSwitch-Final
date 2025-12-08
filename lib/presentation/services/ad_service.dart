import 'dart:io' show Platform;

import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:mediswitch/core/di/locator.dart';
import 'package:mediswitch/presentation/bloc/ad_config_provider.dart';

class AdService {
  InterstitialAd? _interstitialAd;
  int _usageCounter = 0;
  bool _isAdLoaded = false;

  AdService() {
    // Listen to config changes to retry loading if ads become enabled
    try {
      locator<AdConfigProvider>().addListener(_onConfigChanged);
      _onConfigChanged(); // Initial check
    } catch (e) {
      print("AdService: Error attaching listener to AdConfigProvider: $e");
    }
  }

  void _onConfigChanged() {
    try {
      final config = locator<AdConfigProvider>();
      if (config.interstitialEnabled && !_isAdLoaded) {
        _loadInterstitialAd();
      }
    } catch (e) {
      print("AdService: Error in _onConfigChanged: $e");
    }
  }

  void _loadInterstitialAd() {
    final config = locator<AdConfigProvider>();

    if (!config.interstitialEnabled) return;

    final String adUnitId =
        Platform.isAndroid
            ? (config.interstitialTestMode
                ? 'ca-app-pub-3940256099942544/1033173712'
                : config.interstitialAdUnitIdAndroid)
            : (config.interstitialTestMode
                ? 'ca-app-pub-3940256099942544/4411468910'
                : config.interstitialAdUnitIdIos);

    if (adUnitId.isEmpty) return;

    InterstitialAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          print('AdService: InterstitialAd loaded.');
          _interstitialAd = ad;
          _isAdLoaded = true;
          _interstitialAd!.setImmersiveMode(true);
        },
        onAdFailedToLoad: (LoadAdError error) {
          print('AdService: InterstitialAd failed to load: $error');
          _interstitialAd = null;
          _isAdLoaded = false;
        },
      ),
    );
  }

  void incrementUsageCounterAndShowAdIfNeeded() {
    final config = locator<AdConfigProvider>();

    if (!config.interstitialEnabled) return;

    _usageCounter++;
    // print("AdService: Usage counter: $_usageCounter / ${config.interstitialAdFrequency}");

    if (_usageCounter >= config.interstitialAdFrequency) {
      _showInterstitialAd();
      _usageCounter = 0;
    }
  }

  void _showInterstitialAd() {
    if (_isAdLoaded && _interstitialAd != null) {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (InterstitialAd ad) {
          print('AdService: InterstitialAd dismissed.');
          ad.dispose();
          _isAdLoaded = false;
          _loadInterstitialAd(); // Load the next one
        },
        onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
          print('AdService: InterstitialAd failed to show: $error');
          ad.dispose();
          _isAdLoaded = false;
          _loadInterstitialAd(); // Retry load
        },
      );
      _interstitialAd!.show();
      _interstitialAd = null; // Clear reference as it's disposed on dismiss
    } else {
      print('AdService: InterstitialAd not ready yet.');
      _loadInterstitialAd(); // Try loading again for next time
    }
  }

  void dispose() {
    _interstitialAd?.dispose();
    try {
      locator<AdConfigProvider>().removeListener(_onConfigChanged);
    } catch (_) {}
  }
}
