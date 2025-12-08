import 'package:flutter/foundation.dart';
import 'package:mediswitch/core/di/locator.dart';
import 'package:mediswitch/core/usecases/usecase.dart';
import 'package:mediswitch/domain/entities/admob_config_entity.dart';
import 'package:mediswitch/domain/usecases/get_admob_config.dart';

/// Provider for managing ad configuration state.
/// Fetches ad config from API and provides it to widgets.
class AdConfigProvider extends ChangeNotifier {
  final GetAdMobConfig _getAdMobConfig;

  AdMobConfigEntity? _config;
  bool _isLoading = false;
  String? _error;

  // Ad placement settings (loaded from config)
  bool _adsEnabled = false;
  bool _testAdsEnabled = true;
  bool _homeBottomEnabled = true;
  bool _searchBottomEnabled = true;
  bool _drugDetailsBottomEnabled = true;
  bool _betweenSearchResultsEnabled = false;
  bool _betweenAlternativesEnabled = false;

  AdConfigProvider({GetAdMobConfig? getAdMobConfig})
    : _getAdMobConfig = getAdMobConfig ?? locator<GetAdMobConfig>() {
    loadConfig();
  }

  // Getters
  AdMobConfigEntity? get config => _config;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get adsEnabled => _adsEnabled && _config != null && _config!.adsEnabled;
  bool get testAdsEnabled => _testAdsEnabled;

  // Placement getters
  // Placement getters
  bool get homeBottomEnabled => adsEnabled && _homeBottomEnabled;
  bool get searchBottomEnabled => adsEnabled && _searchBottomEnabled;
  bool get drugDetailsBottomEnabled => adsEnabled && _drugDetailsBottomEnabled;
  bool get betweenSearchResultsEnabled =>
      adsEnabled && _betweenSearchResultsEnabled;
  bool get betweenAlternativesEnabled =>
      adsEnabled && _betweenAlternativesEnabled;

  // Granular control getters
  bool get bannerEnabled => adsEnabled && (_config?.bannerEnabled ?? true);
  bool get bannerTestMode => _config?.bannerTestMode ?? false;

  bool get interstitialEnabled =>
      adsEnabled && (_config?.interstitialEnabled ?? true);
  bool get interstitialTestMode => _config?.interstitialTestMode ?? false;

  bool get rewardedEnabled => adsEnabled && (_config?.rewardedEnabled ?? true);
  bool get rewardedTestMode => _config?.rewardedTestMode ?? false;

  bool get nativeEnabled => adsEnabled && (_config?.nativeEnabled ?? true);
  bool get nativeTestMode => _config?.nativeTestMode ?? false;

  // Get appropriate ad unit ID based on test mode
  String get bannerAdUnitIdAndroid =>
      _testAdsEnabled
          ? 'ca-app-pub-3940256099942544/6300978111' // Test ID
          : (_config?.bannerAdUnitIdAndroid ?? '');

  String get bannerAdUnitIdIos =>
      _testAdsEnabled
          ? 'ca-app-pub-3940256099942544/2934735716' // Test ID
          : (_config?.bannerAdUnitIdIos ?? '');

  String get interstitialAdUnitIdAndroid =>
      _testAdsEnabled
          ? 'ca-app-pub-3940256099942544/1033173712' // Test ID
          : (_config?.interstitialAdUnitIdAndroid ?? '');

  String get interstitialAdUnitIdIos =>
      _testAdsEnabled
          ? 'ca-app-pub-3940256099942544/4411468910' // Test ID
          : (_config?.interstitialAdUnitIdIos ?? '');

  int get interstitialAdFrequency => _config?.interstitialAdFrequency ?? 10;

  /// Load ad config from API
  Future<void> loadConfig() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _getAdMobConfig(NoParams());

    result.fold(
      (failure) {
        _error = failure.message;
        _isLoading = false;
        // Use defaults when API fails
        _adsEnabled = false;
        notifyListeners();
      },
      (config) {
        _config = config;
        _adsEnabled = config.adsEnabled;
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  /// Refresh config from API
  Future<void> refreshConfig() async {
    await loadConfig();
  }
}
