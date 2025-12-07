import '../../domain/entities/admob_config_entity.dart';

class AdMobConfigModel extends AdMobConfigEntity {
  const AdMobConfigModel({
    required super.admobAppIdAndroid,
    required super.admobAppIdIos,
    required super.bannerAdUnitIdAndroid,
    required super.bannerAdUnitIdIos,
    required super.interstitialAdUnitIdAndroid,
    required super.interstitialAdUnitIdIos,
    required super.adsEnabled,
    required super.testAdsEnabled,
    required super.homeBottomEnabled,
    required super.searchBottomEnabled,
    required super.drugDetailsBottomEnabled,
    required super.betweenSearchResultsEnabled,
    required super.betweenAlternativesEnabled,
    required super.interstitialAdFrequency,
  });

  factory AdMobConfigModel.fromJson(Map<String, dynamic> json) {
    return AdMobConfigModel(
      admobAppIdAndroid: json['admob_app_id_android'] as String? ?? '',
      admobAppIdIos: json['admob_app_id_ios'] as String? ?? '',
      bannerAdUnitIdAndroid: json['banner_ad_unit_id_android'] as String? ?? '',
      bannerAdUnitIdIos: json['banner_ad_unit_id_ios'] as String? ?? '',
      interstitialAdUnitIdAndroid:
          json['interstitial_ad_unit_id_android'] as String? ?? '',
      interstitialAdUnitIdIos:
          json['interstitial_ad_unit_id_ios'] as String? ?? '',
      adsEnabled: json['ads_enabled'] != 'false',
      testAdsEnabled: json['test_ads_enabled'] != 'false',
      homeBottomEnabled: json['ad_placement_home_bottom'] != 'false',
      searchBottomEnabled: json['ad_placement_search_bottom'] != 'false',
      drugDetailsBottomEnabled:
          json['ad_placement_drug_details_bottom'] != 'false',
      betweenSearchResultsEnabled:
          json['ad_placement_between_search_results'] == 'true',
      betweenAlternativesEnabled:
          json['ad_placement_between_alternatives'] == 'true',
      interstitialAdFrequency: json['interstitial_ad_frequency'] as int? ?? 10,
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
      'ads_enabled': adsEnabled,
      'test_ads_enabled': testAdsEnabled,
      'ad_placement_home_bottom': homeBottomEnabled,
      'ad_placement_search_bottom': searchBottomEnabled,
      'ad_placement_drug_details_bottom': drugDetailsBottomEnabled,
      'ad_placement_between_search_results': betweenSearchResultsEnabled,
      'ad_placement_between_alternatives': betweenAlternativesEnabled,
      'interstitial_ad_frequency': interstitialAdFrequency,
    };
  }
}
