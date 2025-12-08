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
  // We now use _config properties directly instead of local state variables to ensure single source of truth

  AdConfigProvider({GetAdMobConfig? getAdMobConfig})
    : _getAdMobConfig = getAdMobConfig ?? locator<GetAdMobConfig>() {
    loadConfig();
  }

  // Getters
  AdMobConfigEntity? get config => _config;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get adsEnabled => _config?.adsEnabled ?? false;

  // Placement getters
  bool get homeBottomEnabled =>
      adsEnabled && (_config?.homeBottomEnabled ?? true);
  bool get searchBottomEnabled =>
      adsEnabled && (_config?.searchBottomEnabled ?? true);
  bool get drugDetailsBottomEnabled =>
      adsEnabled && (_config?.drugDetailsBottomEnabled ?? true);
  bool get betweenSearchResultsEnabled =>
      adsEnabled && (_config?.betweenSearchResultsEnabled ?? false);
  bool get betweenAlternativesEnabled =>
      adsEnabled && (_config?.betweenAlternativesEnabled ?? false);

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
      bannerTestMode
          ? 'ca-app-pub-3940256099942544/6300978111' // Test ID
          : (_config?.bannerAdUnitIdAndroid ?? '');

  String get bannerAdUnitIdIos =>
      bannerTestMode
          ? 'ca-app-pub-3940256099942544/2934735716' // Test ID
          : (_config?.bannerAdUnitIdIos ?? '');

  String get interstitialAdUnitIdAndroid =>
      interstitialTestMode
          ? 'ca-app-pub-3940256099942544/1033173712' // Test ID
          : (_config?.interstitialAdUnitIdAndroid ?? '');

  String get interstitialAdUnitIdIos =>
      interstitialTestMode
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
        print("AdConfigProvider: Failed to load config: ${failure.message}");
        _error = failure.message;
        _isLoading = false;
        notifyListeners();
      },
      (config) {
        print(
          "AdConfigProvider: Loaded config. Ads enabled: ${config.adsEnabled}, Banner Test: ${config.bannerTestMode}",
        );
        _config = config;
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
