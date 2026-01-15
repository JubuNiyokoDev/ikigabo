import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unity_ads_plugin/unity_ads_plugin.dart';
import '../providers/banner_provider.dart';
import 'admob_banner_widget.dart';
import 'dart:math';

class BannerAdWidget extends ConsumerStatefulWidget {
  const BannerAdWidget({super.key});

  @override
  ConsumerState<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends ConsumerState<BannerAdWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;
  final Random _random = Random();
  late bool _useUnityBanner;

  @override
  void initState() {
    super.initState();
    // Alternance 50/50 entre Unity et AdMob
    _useUnityBanner = _random.nextBool();
    
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
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bannerState = ref.watch(bannerProvider);
    
    // Animer selon l'état
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
            child: _useUnityBanner
                ? UnityBannerAd(
                    placementId: 'Banner_Android',
                    onLoad: (placementId) => print('Unity Banner chargé: $placementId'),
                    onClick: (placementId) => print('Unity Banner cliqué: $placementId'),
                    onFailed: (placementId, error, message) {
                      // Ignorer les erreurs noFill (normales)
                      if (error.toString().contains('noFill')) return;
                      print('Unity Banner erreur: $error - $message');
                    },
                  )
                : const AdMobBannerWidget(),
          ),
        );
      },
    );
  }
}
