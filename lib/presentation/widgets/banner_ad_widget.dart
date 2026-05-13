import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unity_ads_plugin/unity_ads_plugin.dart';
import '../../core/services/ad_network_config.dart';
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

  late bool _showAdMob;
  bool _unityReady = false;
  bool _admobReady = false;
  Timer? _rotateTimer;

  @override
  void initState() {
    super.initState();
    _showAdMob =
        AdNetworkConfig.canUseAdMob &&
        AdNetworkConfig.bannerPrimaryNetwork == AdNetwork.admob;

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
    if (!AdNetworkConfig.canUseAdMob) return;

    _rotateTimer = Timer.periodic(AdNetworkConfig.bannerRotationInterval, (_) {
      if (!mounted) return;
      setState(() {
        _showAdMob = !_showAdMob;
        if (_showAdMob) {
          _admobReady = false;
        } else {
          _unityReady = false;
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
            child: SizedBox(
              width: double.infinity,
              height: _bannerHeight.h,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _showAdMob
                    ? AdMobBannerWidget(
                        key: const ValueKey('admob-banner'),
                        onLoaded: _onAdMobReady,
                        onFailed: _onAdMobFailed,
                      )
                    : UnityBannerAd(
                        key: const ValueKey('unity-banner'),
                        placementId: 'Banner_Android',
                        onLoad: (placementId) {
                          print('Unity Banner chargé: $placementId');
                          _onUnityReady();
                        },
                        onClick: (placementId) =>
                            print('Unity Banner cliqué: $placementId'),
                        onShown: (placementId) {
                          print('Unity Banner affiché: $placementId');
                          _onUnityReady();
                        },
                        onFailed: (placementId, error, message) {
                          print(
                            'Unity Banner erreur: '
                            '$placementId - $error - $message',
                          );
                          _onUnityFailed();
                        },
                      ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _onUnityReady() {
    if (!mounted) return;
    if (_unityReady) return;
    setState(() => _unityReady = true);
  }

  void _onUnityFailed() {
    if (!mounted) return;
    setState(() {
      _unityReady = false;
      if (AdNetworkConfig.canUseAdMob) _showAdMob = true;
    });
  }

  void _onAdMobReady() {
    if (!mounted) return;
    if (_admobReady) return;
    setState(() {
      _admobReady = true;
    });
  }

  void _onAdMobFailed() {
    if (!mounted) return;
    setState(() {
      _admobReady = false;
      _showAdMob = false;
    });
  }
}
