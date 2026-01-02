import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:mediswitch/presentation/bloc/ad_config_provider.dart';

/// Service for managing Rewarded Ads
/// Allows users to watch ads in exchange for rewards
class RewardedAdService {
  RewardedAd? _rewardedAd;
  bool _isAdLoaded = false;
  final AdConfigProvider _configProvider;

  RewardedAdService(this._configProvider);

  /// Load a rewarded ad
  Future<void> loadAd() async {
    final config = _configProvider.config;

    // Check if rewarded ads are enabled
    if (config == null || !(config.rewardedEnabled)) {
      debugPrint('Rewarded ads are disabled');
      return;
    }

    // Get ad unit ID based on platform and test mode
    String adUnitId;
    if (config.rewardedTestMode) {
      // Test ad unit IDs
      adUnitId =
          defaultTargetPlatform == TargetPlatform.android
              ? 'ca-app-pub-3940256099942544/5224354917' // Google test ID
              : 'ca-app-pub-3940256099942544/1712485313';
    } else {
      // Production ad unit IDs from config
      adUnitId =
          defaultTargetPlatform == TargetPlatform.android
              ? ((config.rewardedAdUnitIdAndroid).isNotEmpty
                  ? config.rewardedAdUnitIdAndroid
                  : 'ca-app-pub-3940256099942544/5224354917')
              : ((config.rewardedAdUnitIdIos).isNotEmpty
                  ? config.rewardedAdUnitIdIos
                  : 'ca-app-pub-3940256099942544/1712485313');
    }

    debugPrint('Loading rewarded ad with unit ID: $adUnitId');

    try {
      await RewardedAd.load(
        adUnitId: adUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            debugPrint('Rewarded ad loaded successfully');
            _rewardedAd = ad;
            _isAdLoaded = true;

            // Set up full screen content callback
            _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
              onAdShowedFullScreenContent: (ad) {
                debugPrint('Rewarded ad showed full screen content');
              },
              onAdDismissedFullScreenContent: (ad) {
                debugPrint('Rewarded ad dismissed');
                ad.dispose();
                _rewardedAd = null;
                _isAdLoaded = false;
                // Preload next ad
                loadAd();
              },
              onAdFailedToShowFullScreenContent: (ad, error) {
                debugPrint('Rewarded ad failed to show: $error');
                ad.dispose();
                _rewardedAd = null;
                _isAdLoaded = false;
              },
            );
          },
          onAdFailedToLoad: (error) {
            debugPrint('Rewarded ad failed to load: $error');
            _rewardedAd = null;
            _isAdLoaded = false;
          },
        ),
      );
    } catch (e) {
      debugPrint('Error loading rewarded ad: $e');
      _isAdLoaded = false;
    }
  }

  /// Show the rewarded ad and return the reward
  /// Returns Future<RewardItem?> - null if ad wasn't shown or user closed early
  Future<RewardItem?> showAd() async {
    if (!_isAdLoaded || _rewardedAd == null) {
      debugPrint('Rewarded ad not ready');
      await loadAd();
      return null;
    }

    RewardItem? reward;

    try {
      await _rewardedAd!.show(
        onUserEarnedReward: (ad, rewardItem) {
          debugPrint(
            'User earned reward: ${rewardItem.amount} ${rewardItem.type}',
          );
          reward = rewardItem;
        },
      );
    } catch (e) {
      debugPrint('Error showing rewarded ad: $e');
    }

    return reward;
  }

  /// Check if ad is ready to show
  bool get isAdReady => _isAdLoaded && _rewardedAd != null;

  /// Dispose the ad
  void dispose() {
    _rewardedAd?.dispose();
    _rewardedAd = null;
    _isAdLoaded = false;
  }
}

/// Reward types available in the app
enum RewardType { unlockPremium24h, removeAds1h, pdfExport, extraFavorite }

/// Extension to get reward display info
extension RewardTypeExtension on RewardType {
  String get title {
    switch (this) {
      case RewardType.unlockPremium24h:
        return 'Unlock Premium (24 hours)';
      case RewardType.removeAds1h:
        return 'Remove Ads (1 hour)';
      case RewardType.pdfExport:
        return 'Export PDF (1 time)';
      case RewardType.extraFavorite:
        return 'Extra Favorite Slot';
    }
  }

  String get titleAr {
    switch (this) {
      case RewardType.unlockPremium24h:
        return 'فتح المميزات (24 ساعة)';
      case RewardType.removeAds1h:
        return 'إزالة الإعلانات (ساعة واحدة)';
      case RewardType.pdfExport:
        return 'تصدير PDF (مرة واحدة)';
      case RewardType.extraFavorite:
        return 'خانة مفضلة إضافية';
    }
  }

  String get description {
    switch (this) {
      case RewardType.unlockPremium24h:
        return 'Get full access to all premium features for 24 hours';
      case RewardType.removeAds1h:
        return 'Enjoy ad-free experience for 1 hour';
      case RewardType.pdfExport:
        return 'Export drug information as PDF';
      case RewardType.extraFavorite:
        return 'Add one more drug to your favorites';
    }
  }

  String get descriptionAr {
    switch (this) {
      case RewardType.unlockPremium24h:
        return 'احصل على وصول كامل لجميع المميزات لمدة 24 ساعة';
      case RewardType.removeAds1h:
        return 'استمتع بتجربة بدون إعلانات لمدة ساعة واحدة';
      case RewardType.pdfExport:
        return 'قم بتصدير معلومات الدواء كملف PDF';
      case RewardType.extraFavorite:
        return 'أضف دواء إضافي واحد إلى مفضلاتك';
    }
  }

  String get icon {
    switch (this) {
      case RewardType.unlockPremium24h:
        return '💎';
      case RewardType.removeAds1h:
        return '🚫';
      case RewardType.pdfExport:
        return '📄';
      case RewardType.extraFavorite:
        return '⭐';
    }
  }
}
