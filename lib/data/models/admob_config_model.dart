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
      adsEnabled: json['ads_enabled'] as bool? ?? false,
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
      'interstitial_ad_frequency': interstitialAdFrequency,
    };
  }
}
