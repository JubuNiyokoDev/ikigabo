import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:secmtp_sdk/at_index.dart';

import '../../core/services/ad_policy.dart';
import '../../core/services/ads_service.dart';
import '../../core/services/topon_ad_config.dart';
import 'shimmer_widget.dart';

class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  bool _loaded = false;
  bool _loading = false;
  double? _requestedWidth;
  Timer? _initialLoadTimer;
  Timer? _retryTimer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final width = math.min(320.0, MediaQuery.sizeOf(context).width);
    if (_requestedWidth == width) return;
    _requestedWidth = width;
    _initialLoadTimer?.cancel();
    _initialLoadTimer = Timer(const Duration(milliseconds: 1200), () {
      if (mounted) unawaited(_load(width));
    });
  }

  Future<void> _load(double width) async {
    if (_loading) return;
    _loading = true;
    final loaded = await AdsService.loadBanner(
      placementId: TopOnAdConfig.bannerPlacementId,
      width: width,
      height: 50,
    );
    _loading = false;

    if (!mounted) return;
    setState(() => _loaded = loaded);
    if (!loaded) _scheduleRetry();
  }

  void _scheduleRetry() {
    _retryTimer?.cancel();
    _retryTimer = Timer(AdPolicy.bannerRetryDelay, () {
      final width = _requestedWidth;
      if (mounted && width != null) unawaited(_load(width));
    });
  }

  @override
  void dispose() {
    _initialLoadTimer?.cancel();
    _retryTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = _requestedWidth ?? 320;
    if (!_loaded) {
      if (!kDebugMode) return const SizedBox.shrink();
      return Center(
        child: ShimmerWidget(
          width: width,
          height: 50,
          borderRadius: BorderRadius.circular(6),
        ),
      );
    }

    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      child: Center(
        child: SizedBox(
          width: width,
          height: 50,
          child: PlatformBannerWidget(TopOnAdConfig.bannerPlacementId),
        ),
      ),
    );
  }
}
