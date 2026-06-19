import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:secmtp_sdk/at_index.dart';

import '../../core/services/ad_policy.dart';
import '../../core/services/ads_service.dart';
import '../../core/services/topon_ad_config.dart';
import 'shimmer_widget.dart';

class NativeAdListItem extends StatefulWidget {
  const NativeAdListItem({super.key});

  @override
  State<NativeAdListItem> createState() => _NativeAdListItemState();
}

class _NativeAdListItemState extends State<NativeAdListItem> {
  static const double _height = 250;
  bool _loaded = false;
  bool _loading = false;
  double? _width;
  Timer? _retryTimer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final width = MediaQuery.sizeOf(context).width - 32;
    if (_width == width) return;
    _width = width;
    unawaited(_load(width));
  }

  Future<void> _load(double width) async {
    if (_loading) return;
    _loading = true;
    final loaded = await AdsService.loadNative(width: width, height: _height);
    _loading = false;

    if (!mounted) return;
    setState(() => _loaded = loaded);
    if (!loaded) {
      _retryTimer?.cancel();
      _retryTimer = Timer(AdPolicy.bannerRetryDelay, () {
        if (mounted) unawaited(_load(width));
      });
    }
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    unawaited(AdsService.removeNative());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = _width;
    if (width == null) return const SizedBox.shrink();

    if (!_loaded) {
      if (!kDebugMode) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: ShimmerWidget(
          width: width,
          height: _height,
          borderRadius: BorderRadius.circular(6),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: SizedBox(
        width: width,
        height: _height,
        child: PlatformNativeWidget(
          TopOnAdConfig.nativePlacementId,
          _nativeLayout(width),
        ),
      ),
    );
  }

  Map<String, Object> _nativeLayout(double width) {
    return {
      ATNativeManager.parent(): ATNativeManager.createNativeSubViewAttribute(
        width,
        _height,
        backgroundColorStr: '#FFFFFF',
      ),
      ATNativeManager.appIcon(): ATNativeManager.createNativeSubViewAttribute(
        48,
        48,
        x: 12,
        y: 12,
        backgroundColorStr: 'clearColor',
        cornerRadius: 8,
      ),
      ATNativeManager.mainTitle(): ATNativeManager.createNativeSubViewAttribute(
        width - 150,
        24,
        x: 72,
        y: 12,
        textSize: 15,
        backgroundColorStr: 'clearColor',
      ),
      ATNativeManager.desc(): ATNativeManager.createNativeSubViewAttribute(
        width - 150,
        36,
        x: 72,
        y: 40,
        textSize: 13,
        backgroundColorStr: 'clearColor',
      ),
      ATNativeManager.cta(): ATNativeManager.createNativeSubViewAttribute(
        72,
        44,
        x: width - 84,
        y: 16,
        textSize: 13,
        textColorStr: '#FFFFFF',
        backgroundColorStr: '#176B5B',
        textAlignmentStr: 'center',
        cornerRadius: 6,
      ),
      ATNativeManager.mainImage(): ATNativeManager.createNativeSubViewAttribute(
        width - 24,
        145,
        x: 12,
        y: 88,
        backgroundColorStr: '#00000000',
        cornerRadius: 6,
      ),
      ATNativeManager.dislike(): ATNativeManager.createNativeSubViewAttribute(
        20,
        20,
        x: width - 28,
        y: 4,
      ),
      ATNativeManager.elementsView():
          ATNativeManager.createNativeSubViewAttribute(
            width,
            17,
            x: 0,
            y: 233,
            textSize: 10,
            textColorStr: '#FFFFFF',
            backgroundColorStr: '#7F000000',
          ),
    };
  }
}
