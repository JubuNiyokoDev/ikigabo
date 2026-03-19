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
  static const double _unityBannerHeight = 52;
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late bool _showAdMobBanner;
  bool _isUnityLoaded = false;
  bool _hideUnityBanner = false;
  String _bannerDebugLabel = 'Banner loading...';

  @override
  void initState() {
    super.initState();
    _showAdMobBanner =
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
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bannerState = ref.watch(bannerProvider);

    if (_hideUnityBanner) {
      if (!AdNetworkConfig.showBannerDebugState) {
        return const SizedBox.shrink();
      }

      return _buildDebugState(context);
    }

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
            child: _showAdMobBanner
                ? const AdMobBannerWidget()
                : AnimatedSize(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOut,
                    child: ClipRect(
                      child: Align(
                        alignment: Alignment.center,
                        heightFactor: _isUnityLoaded ? 1 : 0,
                        child: SizedBox(
                          height: _unityBannerHeight.h,
                          child: UnityBannerAd(
                            placementId: 'Banner_Android',
                            onLoad: (placementId) {
                              if (!mounted) return;
                              setState(() {
                                _isUnityLoaded = true;
                                _hideUnityBanner = false;
                                _bannerDebugLabel =
                                    'Banner loaded: $placementId';
                              });
                              print('Unity Banner chargé: $placementId');
                            },
                            onClick: (placementId) =>
                                print('Unity Banner cliqué: $placementId'),
                            onShown: (placementId) {
                              if (!mounted) return;
                              setState(() {
                                _bannerDebugLabel =
                                    'Banner shown: $placementId';
                              });
                              print('Unity Banner affiché: $placementId');
                            },
                            onFailed: (placementId, error, message) {
                              if (!mounted) return;

                              if (AdNetworkConfig.canUseAdMob) {
                                setState(() {
                                  _showAdMobBanner = true;
                                  _isUnityLoaded = false;
                                  _bannerDebugLabel =
                                      'Unity failed, fallback AdMob: $error';
                                });
                                print(
                                  'Unity Banner erreur, fallback AdMob: '
                                  '$placementId - $error - $message',
                                );
                                return;
                              }

                              setState(() {
                                _isUnityLoaded = false;
                                _hideUnityBanner = true;
                                _bannerDebugLabel =
                                    'Unity banner failed: $error - $message';
                              });

                              print('Unity Banner erreur: $error - $message');
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
        );
      },
    );
  }

  Widget _buildDebugState(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: 44.h),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.35)),
      ),
      child: Text(
        _bannerDebugLabel,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 11.sp,
          fontWeight: FontWeight.w600,
          color: Colors.orange.shade900,
        ),
      ),
    );
  }
}
