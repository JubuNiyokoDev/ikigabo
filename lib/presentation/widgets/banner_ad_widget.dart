import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unity_ads_plugin/unity_ads_plugin.dart';
import '../../core/services/ad_network_config.dart';
import '../../core/services/meta_ads_service.dart';
import '../providers/banner_provider.dart';
import 'admob_banner_widget.dart';

enum _BannerNetwork { meta, unity, admob }

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

  _BannerNetwork _network = AdNetworkConfig.canUseMeta
      ? _BannerNetwork.meta
      : _BannerNetwork.unity;
  bool _metaLoaded = false;
  bool _unityLoaded = false;
  Timer? _metaRetryTimer;
  Timer? _metaFallbackTimer;

  @override
  void initState() {
    super.initState();
    if (AdNetworkConfig.canUseMeta) {
      MetaAdsService.onBannerResult = _onMetaBannerResult;
    }

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

    if (AdNetworkConfig.canUseMeta) {
      _loadMetaBanner();
      _startMetaFallback();
      _startMetaRetry();
    }
  }

  void _onMetaBannerResult(bool loaded) {
    if (!mounted) return;
    setState(() {
      _metaLoaded = loaded;
      if (loaded) {
        _network = _BannerNetwork.meta;
      } else if (_network == _BannerNetwork.meta) {
        _network = _BannerNetwork.unity;
      }
    });
  }

  void _onAdMobBannerLoaded() {
    if (!mounted || _metaLoaded || _unityLoaded) return;
    setState(() => _network = _BannerNetwork.admob);
  }

  void _onAdMobBannerFailed() {
    if (!mounted || _metaLoaded) return;
    setState(() => _network = _BannerNetwork.unity);
  }

  Future<void> _loadMetaBanner() async {
    await MetaAdsService.loadBanner();
  }

  void _startMetaFallback() {
    _metaFallbackTimer?.cancel();
    _metaFallbackTimer = Timer(AdNetworkConfig.bannerInitialFallbackDelay, () {
      if (!mounted || _metaLoaded || _network != _BannerNetwork.meta) return;
      setState(() => _network = _BannerNetwork.unity);
    });
  }

  void _startMetaRetry() {
    _metaRetryTimer = Timer.periodic(AdNetworkConfig.bannerRetryDelay, (_) {
      if (!mounted) return;
      if (!_metaLoaded) {
        unawaited(_loadMetaBanner());
      }
    });
  }

  @override
  void dispose() {
    if (AdNetworkConfig.canUseMeta) {
      MetaAdsService.onBannerResult = null;
    }
    _metaRetryTimer?.cancel();
    _metaFallbackTimer?.cancel();
    _animationController.dispose();
    MetaAdsService.destroyBanner();
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
                child: _buildBanner(),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBanner() {
    switch (_network) {
      case _BannerNetwork.meta:
        if (_metaLoaded) {
          return _MetaBannerView(key: const ValueKey('meta-banner'));
        }
        return const SizedBox.shrink(key: ValueKey('banner-loading'));
      case _BannerNetwork.unity:
        return _buildUnityBanner();
      case _BannerNetwork.admob:
        if (AdNetworkConfig.canUseAdMob) {
          return AdMobBannerWidget(
            key: const ValueKey('admob-banner'),
            onLoaded: _onAdMobBannerLoaded,
            onFailed: _onAdMobBannerFailed,
          );
        }
        return _buildUnityBanner();
    }
  }

  Widget _buildUnityBanner() {
    return UnityBannerAd(
      key: const ValueKey('unity-banner'),
      placementId: 'Banner_Android',
      onLoad: (_) {
        if (mounted) setState(() => _unityLoaded = true);
      },
      onShown: (_) {
        if (mounted) setState(() => _unityLoaded = true);
      },
      onFailed: (_, __, ___) {
        if (!mounted) return;
        setState(() {
          _unityLoaded = false;
          if (AdNetworkConfig.canUseAdMob) {
            _network = _BannerNetwork.admob;
          }
        });
      },
      onClick: (_) {},
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
