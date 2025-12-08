import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';

import '../bloc/ad_config_provider.dart';

enum BannerAdPlacement { homeBottom, searchBottom, drugDetailsBottom, generic }

class BannerAdWidget extends StatefulWidget {
  final BannerAdPlacement placement;

  const BannerAdWidget({super.key, this.placement = BannerAdPlacement.generic});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    // Load ad after frame build to ensure provider is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAd();
    });
  }

  void _loadAd() {
    final adConfig = context.read<AdConfigProvider>();

    // Check if ads are globally enabled
    // Check if banners are enabled specifically
    if (!adConfig.bannerEnabled) return;

    // Check placement-specific setting
    bool placementEnabled = true;
    switch (widget.placement) {
      case BannerAdPlacement.homeBottom:
        placementEnabled = adConfig.homeBottomEnabled;
        break;
      case BannerAdPlacement.searchBottom:
        placementEnabled = adConfig.searchBottomEnabled;
        break;
      case BannerAdPlacement.drugDetailsBottom:
        placementEnabled = adConfig.drugDetailsBottomEnabled;
        break;
      case BannerAdPlacement.generic:
        placementEnabled = true;
        break;
    }

    if (!placementEnabled) return;

    final String adUnitId =
        Platform.isAndroid
            ? (adConfig.bannerTestMode
                ? 'ca-app-pub-3940256099942544/6300978111'
                : adConfig.bannerAdUnitIdAndroid)
            : (adConfig.bannerTestMode
                ? 'ca-app-pub-3940256099942544/2934735716'
                : adConfig.bannerAdUnitIdIos);

    if (adUnitId.isEmpty) return;

    _bannerAd = BannerAd(
      adUnitId: adUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (Ad ad) {
          if (mounted) {
            setState(() {
              _isAdLoaded = true;
            });
          }
        },
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          print('BannerAd failed to load: $error');
          ad.dispose();
          if (mounted) {
            setState(() {
              _isAdLoaded = false;
            });
          }
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Listen to changes in ad config (e.g. if user disables ads in real-time)
    final adConfig = context.watch<AdConfigProvider>();

    bool shouldShow = adConfig.bannerEnabled;
    if (shouldShow) {
      switch (widget.placement) {
        case BannerAdPlacement.homeBottom:
          shouldShow = adConfig.homeBottomEnabled;
          break;
        case BannerAdPlacement.searchBottom:
          shouldShow = adConfig.searchBottomEnabled;
          break;
        case BannerAdPlacement.drugDetailsBottom:
          shouldShow = adConfig.drugDetailsBottomEnabled;
          break;
        case BannerAdPlacement.generic:
          shouldShow = true;
          break;
      }
    }

    if (shouldShow && _isAdLoaded && _bannerAd != null) {
      return Container(
        alignment: Alignment.center,
        width: _bannerAd!.size.width.toDouble(),
        height: _bannerAd!.size.height.toDouble(),
        child: AdWidget(ad: _bannerAd!),
      );
    } else {
      return const SizedBox.shrink();
    }
  }
}
