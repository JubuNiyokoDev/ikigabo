import 'dart:async';
import 'package:flutter/services.dart';
import 'ad_network_config.dart';

class MetaAdsService {
  static const MethodChannel _channel = MethodChannel('meta_ads_channel');

  static bool _isInitialized = false;
  static bool _isInterstitialLoaded = false;
  static bool _isRewardedLoaded = false;

  static Completer<bool>? _interstitialLoadCompleter;
  static Completer<bool>? _rewardedLoadCompleter;
  static Completer<void>? _interstitialShowCompleter;
  static Completer<void>? _rewardedShowCompleter;
  static VoidCallback? _pendingReward;

  // Listeners pour banner et rectangle (widgets externes)
  static void Function(bool)? onBannerResult;
  static void Function(bool)? onRectangleResult;

  // ── Init ──────────────────────────────────────────────────────────────────
  static Future<void> initialize() async {
    if (_isInitialized) return;
    _channel.setMethodCallHandler(_handleNativeCallback);
    await _channel.invokeMethod('initialize', {
      'testDeviceId': AdNetworkConfig.useTestAds ? AdNetworkConfig.metaTestDeviceId : null,
    });
    _isInitialized = true;
    print('✅ Meta AN initialized');
    unawaited(loadInterstitial());
    unawaited(loadRewarded());
  }

  static Future<void> _handleNativeCallback(MethodCall call) async {
    switch (call.method) {
      case 'onInterstitialLoaded':
        _isInterstitialLoaded = true;
        print('✅ Meta Interstitial loaded');
        if (_interstitialLoadCompleter != null &&
            !_interstitialLoadCompleter!.isCompleted) {
          _interstitialLoadCompleter!.complete(true);
          _interstitialLoadCompleter = null;
        }
      case 'onInterstitialLoadFailed':
        _isInterstitialLoaded = false;
        print('❌ Meta Interstitial failed: ${call.arguments}');
        if (_interstitialLoadCompleter != null &&
            !_interstitialLoadCompleter!.isCompleted) {
          _interstitialLoadCompleter!.complete(false);
          _interstitialLoadCompleter = null;
        }
      case 'onInterstitialDismissed':
        _isInterstitialLoaded = false;
        print('✅ Meta Interstitial dismissed');
        if (_interstitialShowCompleter != null &&
            !_interstitialShowCompleter!.isCompleted) {
          _interstitialShowCompleter!.complete();
          _interstitialShowCompleter = null;
        }
        unawaited(loadInterstitial());
      case 'onRewardedLoaded':
        _isRewardedLoaded = true;
        print('✅ Meta Rewarded loaded');
        if (_rewardedLoadCompleter != null &&
            !_rewardedLoadCompleter!.isCompleted) {
          _rewardedLoadCompleter!.complete(true);
          _rewardedLoadCompleter = null;
        }
      case 'onRewardedLoadFailed':
        _isRewardedLoaded = false;
        print('❌ Meta Rewarded failed: ${call.arguments}');
        if (_rewardedLoadCompleter != null &&
            !_rewardedLoadCompleter!.isCompleted) {
          _rewardedLoadCompleter!.complete(false);
          _rewardedLoadCompleter = null;
        }
      case 'onRewardedComplete':
        print('🎁 Meta Reward granted');
        _pendingReward?.call();
        _pendingReward = null;
      case 'onRewardedClosed':
        _isRewardedLoaded = false;
        print('✅ Meta Rewarded closed');
        if (_rewardedShowCompleter != null &&
            !_rewardedShowCompleter!.isCompleted) {
          _rewardedShowCompleter!.complete();
          _rewardedShowCompleter = null;
        }
        unawaited(loadRewarded());
      case 'onBannerLoaded':
        onBannerResult?.call(true);
      case 'onBannerLoadFailed':
        print('❌ Meta Banner failed: ${call.arguments}');
        onBannerResult?.call(false);
      case 'onRectangleLoaded':
        onRectangleResult?.call(true);
      case 'onRectangleLoadFailed':
        print('❌ Meta Rectangle failed: ${call.arguments}');
        onRectangleResult?.call(false);
    }
  }

  static Future<void> loadBanner() async {
    if (!_isInitialized) await initialize();
    try {
      await _channel.invokeMethod('loadBanner');
    } catch (e) {
      print('❌ Meta loadBanner error: $e');
    }
  }

  static Future<void> destroyBanner() async {
    try {
      await _channel.invokeMethod('destroyBanner');
    } catch (_) {}
  }

  static Future<void> loadRectangle() async {
    if (!_isInitialized) await initialize();
    try {
      await _channel.invokeMethod('loadRectangle');
    } catch (e) {
      print('❌ Meta loadRectangle error: $e');
    }
  }

  static Future<void> destroyRectangle() async {
    try {
      await _channel.invokeMethod('destroyRectangle');
    } catch (_) {}
  }

  // ── Interstitial ──────────────────────────────────────────────────────────
  static Future<bool> loadInterstitial() async {
    if (!_isInitialized) await initialize();
    if (_isInterstitialLoaded) return true;
    if (_interstitialLoadCompleter != null) {
      return _interstitialLoadCompleter!.future;
    }

    final completer = Completer<bool>();
    _interstitialLoadCompleter = completer;

    try {
      await _channel.invokeMethod('loadInterstitial');
    } catch (e) {
      print('❌ Meta loadInterstitial error: $e');
      _interstitialLoadCompleter = null;
      return false;
    }

    return completer.future.timeout(AdNetworkConfig.adLoadTimeout, onTimeout: () {
      _interstitialLoadCompleter = null;
      if (!completer.isCompleted) completer.complete(false);
      print('⚠️ Meta Interstitial load timeout');
      return false;
    });
  }

  static Future<void> showInterstitialAndWait() async {
    if (!_isInterstitialLoaded) {
      final loaded = await loadInterstitial();
      if (!loaded) {
        print('⚠️ Meta Interstitial not ready');
        return;
      }
    }

    final completer = Completer<void>();
    _interstitialShowCompleter = completer;
    _isInterstitialLoaded = false;

    try {
      await _channel.invokeMethod('showInterstitial');
    } catch (e) {
      print('❌ Meta showInterstitial error: $e');
      _interstitialShowCompleter = null;
      return;
    }

    await completer.future.timeout(const Duration(minutes: 2), onTimeout: () {
      _interstitialShowCompleter = null;
      print('⚠️ Meta Interstitial show timeout');
    });
  }

  // ── Rewarded ──────────────────────────────────────────────────────────────
  static Future<bool> loadRewarded() async {
    if (!_isInitialized) await initialize();
    if (_isRewardedLoaded) return true;
    if (_rewardedLoadCompleter != null) {
      return _rewardedLoadCompleter!.future;
    }

    final completer = Completer<bool>();
    _rewardedLoadCompleter = completer;

    try {
      await _channel.invokeMethod('loadRewarded');
    } catch (e) {
      print('❌ Meta loadRewarded error: $e');
      _rewardedLoadCompleter = null;
      return false;
    }

    return completer.future.timeout(AdNetworkConfig.adLoadTimeout, onTimeout: () {
      _rewardedLoadCompleter = null;
      if (!completer.isCompleted) completer.complete(false);
      print('⚠️ Meta Rewarded load timeout');
      return false;
    });
  }

  static Future<void> showRewardedAndWait({required VoidCallback onReward}) async {
    if (!_isRewardedLoaded) {
      final loaded = await loadRewarded();
      if (!loaded) {
        print('⚠️ Meta Rewarded not ready');
        return;
      }
    }

    final completer = Completer<void>();
    _rewardedShowCompleter = completer;
    _pendingReward = onReward;
    _isRewardedLoaded = false;

    try {
      await _channel.invokeMethod('showRewarded');
    } catch (e) {
      print('❌ Meta showRewarded error: $e');
      _rewardedShowCompleter = null;
      _pendingReward = null;
      return;
    }

    await completer.future.timeout(const Duration(minutes: 2), onTimeout: () {
      _rewardedShowCompleter = null;
      _pendingReward = null;
      print('⚠️ Meta Rewarded show timeout');
    });
  }

  // ── Getters ───────────────────────────────────────────────────────────────
  static bool get isInterstitialReady => _isInterstitialLoaded;
  static bool get isRewardedReady => _isRewardedLoaded;
}
