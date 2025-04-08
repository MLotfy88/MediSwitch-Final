import 'package:equatable/equatable.dart';

class AdMobConfigEntity extends Equatable {
  final String admobAppIdAndroid;
  final String admobAppIdIos;
  final String bannerAdUnitIdAndroid;
  final String bannerAdUnitIdIos;
  final String interstitialAdUnitIdAndroid;
  final String interstitialAdUnitIdIos;
  final bool adsEnabled;
  final int interstitialAdFrequency; // e.g., show after every N uses

  const AdMobConfigEntity({
    required this.admobAppIdAndroid,
    required this.admobAppIdIos,
    required this.bannerAdUnitIdAndroid,
    required this.bannerAdUnitIdIos,
    required this.interstitialAdUnitIdAndroid,
    required this.interstitialAdUnitIdIos,
    required this.adsEnabled,
    required this.interstitialAdFrequency,
  });

  // Default empty state
  factory AdMobConfigEntity.empty() {
    return const AdMobConfigEntity(
      admobAppIdAndroid: '',
      admobAppIdIos: '',
      bannerAdUnitIdAndroid: '',
      bannerAdUnitIdIos: '',
      interstitialAdUnitIdAndroid: '',
      interstitialAdUnitIdIos: '',
      adsEnabled: false,
      interstitialAdFrequency: 10, // Default frequency
    );
  }

  @override
  List<Object?> get props => [
    admobAppIdAndroid,
    admobAppIdIos,
    bannerAdUnitIdAndroid,
    bannerAdUnitIdIos,
    interstitialAdUnitIdAndroid,
    interstitialAdUnitIdIos,
    adsEnabled,
    interstitialAdFrequency,
  ];
}
