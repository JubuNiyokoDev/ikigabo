import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:secmtp_sdk/at_index.dart';

import '../../core/services/ad_policy.dart';
import '../../core/services/ads_service.dart';
import '../../core/services/topon_ad_config.dart';
import 'shimmer_widget.dart';

class MediumRectangleAd extends StatefulWidget {
  const MediumRectangleAd({super.key});

  @override
  State<MediumRectangleAd> createState() => _MediumRectangleAdState();
}

class _MediumRectangleAdState extends State<MediumRectangleAd> {
  bool _loaded = false;
  bool _loading = false;
  Timer? _retryTimer;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    if (_loading) return;
    _loading = true;
    final loaded = await AdsService.loadBanner(
      placementId: TopOnAdConfig.mediumRectanglePlacementId,
      width: 300,
      height: 250,
    );
    _loading = false;

    if (!mounted) return;
    setState(() => _loaded = loaded);
    if (!loaded) {
      _retryTimer?.cancel();
      _retryTimer = Timer(AdPolicy.bannerRetryDelay, _load);
    }
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      if (!kDebugMode) return const SizedBox.shrink();
      return Center(
        child: ShimmerWidget(
          width: 300,
          height: 250,
          borderRadius: BorderRadius.circular(6),
        ),
      );
    }

    return Center(
      child: SizedBox(
        width: 300,
        height: 250,
        child: PlatformBannerWidget(TopOnAdConfig.mediumRectanglePlacementId),
      ),
    );
  }
}
