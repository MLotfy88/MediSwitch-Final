import '../../domain/entities/admob_config_entity.dart';

class AdMobConfigModel extends AdMobConfigEntity {
  const AdMobConfigModel({
    required super.admobAppIdAndroid,
    required super.admobAppIdIos,
    required super.bannerAdUnitIdAndroid,
    required super.bannerAdUnitIdIos,
    required super.interstitialAdUnitIdAndroid,
    required super.interstitialAdUnitIdIos,
    required super.rewardedAdUnitIdAndroid,
    required super.rewardedAdUnitIdIos,
    required super.adsEnabled,
    required super.testAdsEnabled,
    required super.bannerEnabled,
    required super.bannerTestMode,
    required super.interstitialEnabled,
    required super.interstitialTestMode,
    required super.rewardedEnabled,
    required super.rewardedTestMode,
    required super.nativeEnabled,
    required super.nativeTestMode,
    required super.homeBottomEnabled,
    required super.searchBottomEnabled,
    required super.drugDetailsBottomEnabled,
    required super.betweenSearchResultsEnabled,
    required super.betweenAlternativesEnabled,
    required super.interstitialAdFrequency,
  });

  factory AdMobConfigModel.fromJson(Map<String, dynamic> json) {
    // Helper to safely parse boolean strings or booleans
    bool parseBool(dynamic val, bool def) {
      if (val == null) return def;
      if (val is bool) return val;
      return val.toString() == 'true';
    }

    return AdMobConfigModel(
      admobAppIdAndroid: json['admob_app_id_android'] as String? ?? '',
      admobAppIdIos: json['admob_app_id_ios'] as String? ?? '',
      bannerAdUnitIdAndroid: json['banner_ad_unit_id_android'] as String? ?? '',
      bannerAdUnitIdIos: json['banner_ad_unit_id_ios'] as String? ?? '',
      interstitialAdUnitIdAndroid:
          json['interstitial_ad_unit_id_android'] as String? ?? '',
      interstitialAdUnitIdIos:
          json['interstitial_ad_unit_id_ios'] as String? ?? '',
      rewardedAdUnitIdAndroid:
          json['rewarded_ad_unit_id_android'] as String? ?? '',
      rewardedAdUnitIdIos: json['rewarded_ad_unit_id_ios'] as String? ?? '',
      adsEnabled: parseBool(json['ads_master_enabled'], false), // Master switch
      testAdsEnabled: parseBool(json['test_ads_enabled'], true),
      bannerEnabled: parseBool(json['banner_enabled'], true),
      bannerTestMode: parseBool(json['banner_test_mode'], false),
      interstitialEnabled: parseBool(json['interstitial_enabled'], true),
      interstitialTestMode: parseBool(json['interstitial_test_mode'], false),
      rewardedEnabled: parseBool(json['rewarded_enabled'], true),
      rewardedTestMode: parseBool(json['rewarded_test_mode'], false),
      nativeEnabled: parseBool(json['native_enabled'], true),
      nativeTestMode: parseBool(json['native_test_mode'], false),
      homeBottomEnabled: parseBool(json['ad_placement_home_bottom'], true),
      searchBottomEnabled: parseBool(json['ad_placement_search_bottom'], true),
      drugDetailsBottomEnabled: parseBool(
        json['ad_placement_drug_details_bottom'],
        true,
      ),
      betweenSearchResultsEnabled: parseBool(
        json['ad_placement_between_search_results'],
        false,
      ),
      betweenAlternativesEnabled: parseBool(
        json['ad_placement_between_alternatives'],
        false,
      ),
      interstitialAdFrequency:
          int.tryParse(json['interstitial_ad_frequency']?.toString() ?? '10') ??
          10,
    );
  }

  // toJson might be useful later for caching
  Map<String, dynamic> toJson() {
    return {
      'admob_app_id_android': admobAppIdAndroid,
      'admob_app_id_ios': admobAppIdIos,
      'banner_ad_unit_id_android': bannerAdUnitIdAndroid,
      'banner_ad_unit_id_ios': bannerAdUnitIdIos,
      'interstitial_ad_unit_id_android': interstitialAdUnitIdAndroid,
      'interstitial_ad_unit_id_ios': interstitialAdUnitIdIos,
      'ads_master_enabled': adsEnabled,
      'test_ads_enabled': testAdsEnabled,
      'banner_enabled': bannerEnabled,
      'banner_test_mode': bannerTestMode,
      'interstitial_enabled': interstitialEnabled,
      'interstitial_test_mode': interstitialTestMode,
      'rewarded_enabled': rewardedEnabled,
      'rewarded_test_mode': rewardedTestMode,
      'native_enabled': nativeEnabled,
      'native_test_mode': nativeTestMode,
      'ad_placement_home_bottom': homeBottomEnabled,
      'ad_placement_search_bottom': searchBottomEnabled,
      'ad_placement_drug_details_bottom': drugDetailsBottomEnabled,
      'ad_placement_between_search_results': betweenSearchResultsEnabled,
      'ad_placement_between_alternatives': betweenAlternativesEnabled,
      'interstitial_ad_frequency': interstitialAdFrequency,
    };
  }
}
