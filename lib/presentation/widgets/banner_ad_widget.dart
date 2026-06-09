import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unity_ads_plugin/unity_ads_plugin.dart';
import '../providers/banner_provider.dart';

class BannerAdWidget extends ConsumerStatefulWidget {
  const BannerAdWidget({super.key});

  @override
  ConsumerState<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends ConsumerState<BannerAdWidget>
    with SingleTickerProviderStateMixin {
  static const double _bannerHeight = 52;
  static const MethodChannel _metaChannel = MethodChannel('meta_ads_channel');

  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  bool _showMeta = false;
  bool _metaLoaded = false;
  bool _unityLoaded = false;
  Timer? _rotateTimer;

  @override
  void initState() {
    super.initState();
    _metaChannel.setMethodCallHandler(_handleMetaCallback);

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideAnimation = Tween<double>(begin: -1.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _loadMetaBanner();
    _startRotation();
  }

  Future<void> _handleMetaCallback(MethodCall call) async {
    if (!mounted) return;
    switch (call.method) {
      case 'onBannerLoaded':
        setState(() => _metaLoaded = true);
      case 'onBannerLoadFailed':
        setState(() {
          _metaLoaded = false;
          if (_showMeta) _showMeta = false;
        });
    }
  }

  Future<void> _loadMetaBanner() async {
    try {
      await _metaChannel.invokeMethod('loadBanner');
    } catch (_) {}
  }

  void _startRotation() {
    _rotateTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!mounted) return;
      setState(() {
        _showMeta = !_showMeta;
        if (_showMeta && !_metaLoaded) _showMeta = false;
      });
    });
  }

  @override
  void dispose() {
    _rotateTimer?.cancel();
    _animationController.dispose();
    _metaChannel.invokeMethod('destroyBanner').catchError((_) {});
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bannerState = ref.watch(bannerProvider);

    if (bannerState.isVisible) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value * 80.h),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: SizedBox(
              width: double.infinity,
              height: _bannerHeight.h,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _showMeta && _metaLoaded
                    ? _MetaBannerView(key: const ValueKey('meta-banner'))
                    : UnityBannerAd(
                        key: const ValueKey('unity-banner'),
                        placementId: 'Banner_Android',
                        onLoad: (_) {
                          if (mounted) setState(() => _unityLoaded = true);
                        },
                        onShown: (_) {
                          if (mounted) setState(() => _unityLoaded = true);
                        },
                        onFailed: (_, __, ___) {
                          if (mounted) {
                            setState(() {
                              _unityLoaded = false;
                              if (_metaLoaded) _showMeta = true;
                            });
                          }
                        },
                        onClick: (_) {},
                      ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MetaBannerView extends StatelessWidget {
  const _MetaBannerView({super.key});

  @override
  Widget build(BuildContext context) {
    return AndroidView(
      viewType: 'meta_banner_view',
      layoutDirection: TextDirection.ltr,
      creationParamsCodec: const StandardMessageCodec(),
    );
  }
}
