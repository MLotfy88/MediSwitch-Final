import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:io' show Platform; // To check platform

class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;

  // Use test ad unit IDs for development
  // Replace with your actual ad unit IDs before release
  final String _adUnitId =
      Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/6300978111' // Android Test ID
          : 'ca-app-pub-3940256099942544/2934735716'; // iOS Test ID

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    _bannerAd = BannerAd(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      size: AdSize.banner, // Standard banner size
      listener: BannerAdListener(
        onAdLoaded: (Ad ad) {
          print('BannerAd loaded.');
          setState(() {
            _isAdLoaded = true;
          });
        },
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          print('BannerAd failed to load: $error');
          ad.dispose(); // Dispose the failed ad
          setState(() {
            _isAdLoaded = false; // Ensure it's marked as not loaded
          });
          // Optionally retry loading after a delay
          // Future.delayed(Duration(seconds: 30), () => _loadAd());
        },
        onAdOpened: (Ad ad) => print('BannerAd opened.'),
        onAdClosed: (Ad ad) => print('BannerAd closed.'),
        onAdImpression: (Ad ad) => print('BannerAd impression.'),
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
    if (_isAdLoaded && _bannerAd != null) {
      return SizedBox(
        width: _bannerAd!.size.width.toDouble(),
        height: _bannerAd!.size.height.toDouble(),
        child: AdWidget(ad: _bannerAd!),
      );
    } else {
      // Return an empty container or a placeholder if the ad failed to load
      // or hasn't loaded yet. Avoid returning null.
      return const SizedBox.shrink(); // Or Container(height: 50) etc.
    }
  }
}
