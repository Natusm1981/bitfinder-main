// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:bit_finder/constants.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isBannerReady = false;

  @override
  void initState() {
    super.initState();
    _loadBanner();
  }

  Future<void> _loadBanner() async {
    if (!mounted) {
      return;
    }
    _bannerAd = BannerAd(
      adUnitId: kDebugMode ? bannerAdUnitIdTEST : bannerAdUnitIdPROD,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          setState(() {
            _isBannerReady = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          debugPrint('Failed to load a banner ad: ${error.message}');
          setState(() {
            _isBannerReady = false;
          });
        },
      ),
    );

    await _bannerAd!.load();
    debugPrint('Banner ad carregado');
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isBannerReady || _bannerAd == null) {
      return const SizedBox(height: 50);
    }

    return Container(
      alignment: Alignment.center,
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      color: Colors.transparent,
      child: AdWidget(ad: _bannerAd!),
    );
  }
}
