import 'package:equatable/equatable.dart';

class AdMobConfigEntity extends Equatable {
  final String admobAppIdAndroid;
  final String admobAppIdIos;
  final String bannerAdUnitIdAndroid;
  final String bannerAdUnitIdIos;
  final String interstitialAdUnitIdAndroid;
  final String interstitialAdUnitIdIos;
  final bool adsEnabled;
  final bool testAdsEnabled;
  final bool bannerEnabled;
  final bool bannerTestMode;
  final bool interstitialEnabled;
  final bool interstitialTestMode;
  final bool rewardedEnabled;
  final bool rewardedTestMode;
  final bool nativeEnabled;
  final bool nativeTestMode;
  final bool homeBottomEnabled;
  final bool searchBottomEnabled;
  final bool drugDetailsBottomEnabled;
  final bool betweenSearchResultsEnabled;
  final bool betweenAlternativesEnabled;
  final int interstitialAdFrequency; // e.g., show after every N uses

  const AdMobConfigEntity({
    required this.admobAppIdAndroid,
    required this.admobAppIdIos,
    required this.bannerAdUnitIdAndroid,
    required this.bannerAdUnitIdIos,
    required this.interstitialAdUnitIdAndroid,
    required this.interstitialAdUnitIdIos,
    required this.adsEnabled,
    required this.testAdsEnabled,
    required this.bannerEnabled,
    required this.bannerTestMode,
    required this.interstitialEnabled,
    required this.interstitialTestMode,
    required this.rewardedEnabled,
    required this.rewardedTestMode,
    required this.nativeEnabled,
    required this.nativeTestMode,
    required this.homeBottomEnabled,
    required this.searchBottomEnabled,
    required this.drugDetailsBottomEnabled,
    required this.betweenSearchResultsEnabled,
    required this.betweenAlternativesEnabled,
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
      testAdsEnabled: true,
      bannerEnabled: true,
      bannerTestMode: false,
      interstitialEnabled: true,
      interstitialTestMode: false,
      rewardedEnabled: true,
      rewardedTestMode: false,
      nativeEnabled: true,
      nativeTestMode: false,
      homeBottomEnabled: true,
      searchBottomEnabled: true,
      drugDetailsBottomEnabled: true,
      betweenSearchResultsEnabled: false,
      betweenAlternativesEnabled: false,
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
    testAdsEnabled,
    bannerEnabled,
    bannerTestMode,
    interstitialEnabled,
    interstitialTestMode,
    rewardedEnabled,
    rewardedTestMode,
    nativeEnabled,
    nativeTestMode,
    homeBottomEnabled,
    searchBottomEnabled,
    drugDetailsBottomEnabled,
    betweenSearchResultsEnabled,
    betweenAlternativesEnabled,
    interstitialAdFrequency,
  ];
}
