import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:ikigabo/core/services/ad_network_config.dart';
import 'package:ikigabo/core/services/admob_service.dart';

class AdMobBannerWidget extends StatefulWidget {
  final VoidCallback? onLoaded;
  final VoidCallback? onFailed;

  const AdMobBannerWidget({super.key, this.onLoaded, this.onFailed});

  @override
  State<AdMobBannerWidget> createState() => _AdMobBannerWidgetState();
}

class _AdMobBannerWidgetState extends State<AdMobBannerWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;
  Timer? _retryTimer;

  @override
  void initState() {
    super.initState();
    _loadBanner();
  }

  void _loadBanner() {
    _retryTimer?.cancel();
    _bannerAd?.dispose();
    _bannerAd = null;
    _isLoaded = false;

    final bannerAd = AdMobService.createBanner(
      onLoaded: () {
        if (!mounted) return;
        setState(() => _isLoaded = true);
        widget.onLoaded?.call();
      },
      onFailedToLoad: (_) {
        if (!mounted) return;
        setState(() {
          _bannerAd = null;
          _isLoaded = false;
        });
        widget.onFailed?.call();
        _scheduleRetry();
      },
    );

    _bannerAd = bannerAd;
    unawaited(bannerAd.load());
  }

  void _scheduleRetry() {
    _retryTimer?.cancel();
    _retryTimer = Timer(AdNetworkConfig.bannerRetryDelay, _loadBanner);
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded || _bannerAd == null) {
      return const SizedBox.shrink();
    }

    return Container(
      alignment: Alignment.center,
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      child: AdWidget(ad: _bannerAd!),
    );
  }
}
