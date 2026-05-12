import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unity_ads_plugin/unity_ads_plugin.dart';
import '../providers/banner_provider.dart';
import 'admob_banner_widget.dart';

class BannerAdWidget extends ConsumerStatefulWidget {
  const BannerAdWidget({super.key});

  @override
  ConsumerState<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends ConsumerState<BannerAdWidget>
    with SingleTickerProviderStateMixin {
  static const double _bannerHeight = 52;
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  bool _showAdMob = false;
  bool _unityReady = false;
  bool _admobReady = false;
  Timer? _rotateTimer;

  @override
  void initState() {
    super.initState();

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

    _startRotation();
  }

  void _startRotation() {
    _rotateTimer?.cancel();
    _rotateTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!mounted) return;
      setState(() {
        if (_showAdMob && _unityReady) {
          _showAdMob = false;
        } else if (!_showAdMob && _admobReady) {
          _showAdMob = true;
        }
      });
    });
  }

  @override
  void dispose() {
    _rotateTimer?.cancel();
    _animationController.dispose();
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRect(
                  child: Align(
                    heightFactor: _showAdMob ? 0 : 1,
                    child: SizedBox(
                      height: _bannerHeight.h,
                      child: UnityBannerAd(
                        placementId: 'Banner_Android',
                        onLoad: (_) => _onUnityReady(),
                        onClick: (_) => print('Unity Banner cliqué'),
                        onShown: (_) => _onUnityReady(),
                        onFailed: (_, __, ___) => _onUnityFailed(),
                      ),
                    ),
                  ),
                ),
                ClipRect(
                  child: Align(
                    heightFactor: _showAdMob ? 1 : 0,
                    child: SizedBox(
                      height: _bannerHeight.h,
                      child: AdMobBannerWidget(onLoaded: _onAdMobReady),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _onUnityReady() {
    if (!mounted) return;
    setState(() => _unityReady = true);
  }

  void _onUnityFailed() {
    if (!mounted) return;
    setState(() {
      _unityReady = false;
      if (_admobReady) _showAdMob = true;
    });
  }

  void _onAdMobReady() {
    if (!mounted) return;
    setState(() {
      _admobReady = true;
      if (!_unityReady) _showAdMob = true;
    });
  }
}
