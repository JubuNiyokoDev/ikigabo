import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../core/services/ad_network_config.dart';

class NativeAdListItem extends StatefulWidget {
  const NativeAdListItem({super.key});

  @override
  State<NativeAdListItem> createState() => _NativeAdListItemState();
}

class _NativeAdListItemState extends State<NativeAdListItem> {
  static const String _liveAdUnitId = 'ca-app-pub-2300546388710165/7304731135';
  static const String _testAdUnitId = 'ca-app-pub-3940256099942544/2247696110';

  NativeAd? _ad;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    if (!AdNetworkConfig.canUseAdMob) return;
    _ad = NativeAd(
      adUnitId: AdNetworkConfig.useTestAds ? _testAdUnitId : _liveAdUnitId,
      listener: NativeAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          _ad = null;
        },
      ),
      request: const AdRequest(),
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: TemplateType.small,
      ),
    )..load();
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || _ad == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 90, maxHeight: 110),
        child: AdWidget(ad: _ad!),
      ),
    );
  }
}
