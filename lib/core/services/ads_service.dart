import 'dart:async';
import 'dart:ui';
import 'package:unity_ads_plugin/unity_ads_plugin.dart';
import 'ad_network_config.dart';
import 'admob_service.dart';
import 'meta_ads_service.dart';

class AdsService {
  static const String _gameId = '6021741';
  static const String _unityInterstitialId = 'Interstitial_Android';
  static const String _unityRewardedId = 'Rewarded_Android';

  static bool _isInitialized = false;
  static bool _isUnityInitialized = false;
  static bool _isUnityInterstitialLoaded = false;
  static bool _isUnityRewardedLoaded = false;
  static Completer<void>? _initializeCompleter;
  static Completer<bool>? _unityInterstitialLoadCompleter;
  static Completer<bool>? _unityRewardedLoadCompleter;

  // ── Init ──────────────────────────────────────────────────────────────────
  static Future<void> initialize() async {
    if (_isInitialized) return;
    if (_initializeCompleter != null) return _initializeCompleter!.future;

    final completer = Completer<void>();
    _initializeCompleter = completer;

    try {
      await _initializeUnity();
      if (AdNetworkConfig.canUseMeta) await MetaAdsService.initialize();
      if (AdNetworkConfig.canUseAdMob) await AdMobService.initialize();
      _isInitialized = true;
      _preloadAll();
    } finally {
      if (!completer.isCompleted) completer.complete();
      _initializeCompleter = null;
    }
  }

  static void _preloadAll() {
    unawaited(_loadUnityInterstitial());
    unawaited(_loadUnityRewarded());
    if (AdNetworkConfig.canUseMeta) {
      unawaited(MetaAdsService.loadInterstitial());
      unawaited(MetaAdsService.loadRewarded());
    }
    if (AdNetworkConfig.canUseAdMob) {
      unawaited(AdMobService.loadInterstitial());
      unawaited(AdMobService.loadRewarded());
      unawaited(AdMobService.loadAppOpen());
      unawaited(AdMobService.loadRewardedInterstitial());
    }
  }

  // ── Interstitial: Meta d'abord, Unity ensuite, AdMob dernier ──────────────
  static Future<void> showInterstitial() async {
    if (!_isInitialized) await initialize();

    if (await _showMetaInterstitialIfReady()) {
      _preloadAll();
      return;
    }
    if (await _showUnityInterstitialIfReady()) {
      _preloadAll();
      return;
    }
    await _showAdMobInterstitialIfReady();

    _preloadAll();
  }

  // ── Rewarded: Meta d'abord, Unity ensuite, AdMob dernier ──────────────────
  static Future<void> showRewarded({required VoidCallback onReward}) async {
    if (!_isInitialized) await initialize();

    var rewardGranted = false;
    void grantOnce() {
      if (rewardGranted) return;
      rewardGranted = true;
      onReward();
    }

    if (AdNetworkConfig.canUseMeta) {
      final ok = await MetaAdsService.loadRewarded();
      if (ok) {
        await MetaAdsService.showRewardedAndWait(onReward: grantOnce);
        _preloadAll();
        return;
      }
    }

    final unityOk = await _loadUnityRewarded();
    if (unityOk) {
      await _showUnityRewardedAndWait(onReward: grantOnce);
      _preloadAll();
      return;
    }

    if (AdNetworkConfig.canUseAdMob) {
      final rewardedInterstitialOk =
          await AdMobService.loadRewardedInterstitial();
      if (rewardedInterstitialOk) {
        await AdMobService.showRewardedInterstitialAndWait(onReward: grantOnce);
        _preloadAll();
        return;
      }
      final rewardedOk = await AdMobService.loadRewarded();
      if (rewardedOk) {
        await AdMobService.showRewardedAndWait(onReward: grantOnce);
      }
    }

    _preloadAll();
  }

  // ── App Open ──────────────────────────────────────────────────────────────
  static Future<void> showAppOpen() async {
    if (!_isInitialized) await initialize();
    if (AdNetworkConfig.canUseAdMob) {
      final ok = await AdMobService.loadAppOpen();
      if (ok) {
        await AdMobService.showAppOpenAndWait();
        return;
      }
    }
    if (AdNetworkConfig.canUseMeta) {
      await MetaAdsService.showInterstitialAndWait();
    }
  }

  // ── Unity Init ────────────────────────────────────────────────────────────
  static Future<void> _initializeUnity() async {
    final completer = Completer<void>();
    try {
      await UnityAds.init(
        gameId: _gameId,
        testMode: AdNetworkConfig.isUnityTestMode,
        onComplete: () {
          _isUnityInitialized = true;
          const mode = AdNetworkConfig.isUnityTestMode ? 'TEST' : 'PRODUCTION';
          print('✅ Unity Ads initialized ($mode)');
          if (!completer.isCompleted) completer.complete();
        },
        onFailed: (error, message) {
          _isUnityInitialized = false;
          print('❌ Unity Ads init failed: $error - $message');
          if (!completer.isCompleted) completer.complete();
        },
      );
    } catch (error) {
      _isUnityInitialized = false;
      print('❌ Unity Ads init threw: $error');
      if (!completer.isCompleted) completer.complete();
    }
    await completer.future.timeout(
      AdNetworkConfig.adLoadTimeout,
      onTimeout: () {
        print('⚠️ Unity Ads init timeout');
      },
    );
  }

  // ── Unity Load ────────────────────────────────────────────────────────────
  static Future<bool> _loadUnityInterstitial() async {
    if (!_isInitialized) await initialize();
    if (!_isUnityInitialized) return false;
    if (_isUnityInterstitialLoaded) return true;
    if (_unityInterstitialLoadCompleter != null) {
      return _unityInterstitialLoadCompleter!.future;
    }

    final completer = Completer<bool>();
    _unityInterstitialLoadCompleter = completer;

    UnityAds.load(
      placementId: _unityInterstitialId,
      onComplete: (id) {
        _isUnityInterstitialLoaded = true;
        if (identical(_unityInterstitialLoadCompleter, completer)) {
          _unityInterstitialLoadCompleter = null;
        }
        print('✅ Unity Interstitial loaded');
        if (!completer.isCompleted) completer.complete(true);
      },
      onFailed: (id, error, message) {
        _isUnityInterstitialLoaded = false;
        if (identical(_unityInterstitialLoadCompleter, completer)) {
          _unityInterstitialLoadCompleter = null;
        }
        print('❌ Unity Interstitial load failed: $error - $message');
        if (!completer.isCompleted) completer.complete(false);
      },
    );

    return completer.future.timeout(
      AdNetworkConfig.adLoadTimeout,
      onTimeout: () {
        if (identical(_unityInterstitialLoadCompleter, completer)) {
          _unityInterstitialLoadCompleter = null;
        }
        if (!completer.isCompleted) completer.complete(false);
        print('⚠️ Unity Interstitial load timeout');
        return false;
      },
    );
  }

  static Future<bool> _loadUnityRewarded() async {
    if (!_isInitialized) await initialize();
    if (!_isUnityInitialized) return false;
    if (_isUnityRewardedLoaded) return true;
    if (_unityRewardedLoadCompleter != null) {
      return _unityRewardedLoadCompleter!.future;
    }

    final completer = Completer<bool>();
    _unityRewardedLoadCompleter = completer;

    UnityAds.load(
      placementId: _unityRewardedId,
      onComplete: (id) {
        _isUnityRewardedLoaded = true;
        if (identical(_unityRewardedLoadCompleter, completer)) {
          _unityRewardedLoadCompleter = null;
        }
        print('✅ Unity Rewarded loaded');
        if (!completer.isCompleted) completer.complete(true);
      },
      onFailed: (id, error, message) {
        _isUnityRewardedLoaded = false;
        if (identical(_unityRewardedLoadCompleter, completer)) {
          _unityRewardedLoadCompleter = null;
        }
        print('❌ Unity Rewarded load failed: $error - $message');
        if (!completer.isCompleted) completer.complete(false);
      },
    );

    return completer.future.timeout(
      AdNetworkConfig.adLoadTimeout,
      onTimeout: () {
        if (identical(_unityRewardedLoadCompleter, completer)) {
          _unityRewardedLoadCompleter = null;
        }
        if (!completer.isCompleted) completer.complete(false);
        print('⚠️ Unity Rewarded load timeout');
        return false;
      },
    );
  }

  // ── Unity Show ────────────────────────────────────────────────────────────
  static Future<bool> _showMetaInterstitialIfReady() async {
    if (!AdNetworkConfig.canUseMeta) return false;
    final ok = await MetaAdsService.loadInterstitial();
    if (!ok) return false;
    await MetaAdsService.showInterstitialAndWait();
    return true;
  }

  static Future<bool> _showAdMobInterstitialIfReady() async {
    if (!AdNetworkConfig.canUseAdMob) return false;
    final ok = await AdMobService.loadInterstitial();
    if (!ok) return false;
    await AdMobService.showInterstitialAndWait();
    return true;
  }

  static Future<bool> _showUnityInterstitialIfReady() async {
    final ok = await _loadUnityInterstitial();
    if (!ok) return false;
    await _showUnityInterstitialAndWait();
    return true;
  }

  static Future<void> _showUnityInterstitialAndWait() async {
    if (!_isUnityInterstitialLoaded) await _loadUnityInterstitial();
    if (!_isUnityInterstitialLoaded) {
      print('⚠️ Unity Interstitial not ready');
      return;
    }

    final completer = Completer<void>();
    UnityAds.showVideoAd(
      placementId: _unityInterstitialId,
      onStart: (id) => print('▶ Unity Interstitial started'),
      onClick: (id) => print('🖱 Unity Interstitial clicked'),
      onSkipped: (id) {
        _isUnityInterstitialLoaded = false;
        unawaited(_loadUnityInterstitial());
        print('⏭ Unity Interstitial skipped');
        if (!completer.isCompleted) completer.complete();
      },
      onComplete: (id) {
        _isUnityInterstitialLoaded = false;
        unawaited(_loadUnityInterstitial());
        print('✅ Unity Interstitial completed');
        if (!completer.isCompleted) completer.complete();
      },
      onFailed: (id, error, message) {
        _isUnityInterstitialLoaded = false;
        unawaited(_loadUnityInterstitial());
        print('❌ Unity Interstitial failed: $error - $message');
        if (!completer.isCompleted) completer.complete();
      },
    );
    await completer.future.timeout(
      const Duration(minutes: 2),
      onTimeout: () {
        print('⚠️ Unity Interstitial show timeout');
      },
    );
  }

  static Future<void> _showUnityRewardedAndWait({
    required VoidCallback onReward,
  }) async {
    if (!_isUnityRewardedLoaded) await _loadUnityRewarded();
    if (!_isUnityRewardedLoaded) {
      print('⚠️ Unity Rewarded not ready');
      return;
    }

    final completer = Completer<void>();
    UnityAds.showVideoAd(
      placementId: _unityRewardedId,
      onStart: (id) => print('▶ Unity Rewarded started'),
      onClick: (id) => print('🖱 Unity Rewarded clicked'),
      onSkipped: (id) {
        _isUnityRewardedLoaded = false;
        unawaited(_loadUnityRewarded());
        print('⏭ Unity Rewarded skipped');
        if (!completer.isCompleted) completer.complete();
      },
      onComplete: (id) {
        _isUnityRewardedLoaded = false;
        unawaited(_loadUnityRewarded());
        print('🎁 Unity Reward granted');
        onReward();
        if (!completer.isCompleted) completer.complete();
      },
      onFailed: (id, error, message) {
        _isUnityRewardedLoaded = false;
        unawaited(_loadUnityRewarded());
        print('❌ Unity Rewarded failed: $error - $message');
        if (!completer.isCompleted) completer.complete();
      },
    );
    await completer.future.timeout(
      const Duration(minutes: 2),
      onTimeout: () {
        print('⚠️ Unity Rewarded show timeout');
      },
    );
  }

  // ── Getters publics ───────────────────────────────────────────────────────
  static bool get isInterstitialReady => _isUnityInterstitialLoaded;
  static bool get isRewardedReady => _isUnityRewardedLoaded;
  static Future<bool> loadInterstitial() => _loadUnityInterstitial();
  static Future<bool> loadRewarded() => _loadUnityRewarded();
}
