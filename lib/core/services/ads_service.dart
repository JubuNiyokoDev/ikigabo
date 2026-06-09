import 'dart:async';
import 'dart:ui';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unity_ads_plugin/unity_ads_plugin.dart';
import 'ad_network_config.dart';
import 'admob_service.dart';
import 'meta_ads_service.dart';

/// Alternance plein écran sur 8 tours :
/// 0=Meta Interstitial,        1=Unity Interstitial,
/// 2=Meta Rewarded,            3=Unity Rewarded,
/// 4=AdMob RewardedInterstitial, 5=AdMob AppOpen,
/// 6=Meta Interstitial,        7=Unity Interstitial
const String _turnKey = 'ad_turn_index';
const int _totalFormats = 8;

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

  // ── Tour suivant ──────────────────────────────────────────────────────────
  static Future<int> _nextTurn() async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_turnKey) ?? 0;
    await prefs.setInt(_turnKey, (current + 1) % _totalFormats);
    return current;
  }

  // ── Interstitial (sans récompense) ────────────────────────────────────────
  static Future<void> showInterstitial() async {
    if (!_isInitialized) await initialize();
    final turn = await _nextTurn();

    switch (turn) {
      case 0:
      case 6: // Meta Interstitial → Unity fallback
        if (AdNetworkConfig.canUseMeta) {
          final ok = await MetaAdsService.loadInterstitial();
          if (ok) { await MetaAdsService.showInterstitialAndWait(); break; }
        }
        await _showUnityInterstitialAndWait();
      case 1:
      case 7: // Unity Interstitial → Meta fallback
        final ok = await _loadUnityInterstitial();
        if (ok) {
          await _showUnityInterstitialAndWait();
        } else if (AdNetworkConfig.canUseMeta) {
          await MetaAdsService.showInterstitialAndWait();
        }
      case 2: // Meta Rewarded sans gate → Unity fallback
        if (AdNetworkConfig.canUseMeta) {
          final ok = await MetaAdsService.loadRewarded();
          if (ok) { await MetaAdsService.showRewardedAndWait(onReward: () {}); break; }
        }
        await _showUnityInterstitialAndWait();
      case 3: // Unity Rewarded sans gate → Meta fallback
        final ok = await _loadUnityRewarded();
        if (ok) {
          await _showUnityRewardedAndWait(onReward: () {});
        } else if (AdNetworkConfig.canUseMeta) {
          await MetaAdsService.showRewardedAndWait(onReward: () {});
        }
      case 4: // AdMob RewardedInterstitial → Unity fallback
        if (AdNetworkConfig.canUseAdMob) {
          final ok = await AdMobService.loadRewardedInterstitial();
          if (ok) { await AdMobService.showRewardedInterstitialAndWait(onReward: () {}); break; }
        }
        await _showUnityInterstitialAndWait();
      case 5: // AdMob AppOpen → Meta fallback
        if (AdNetworkConfig.canUseAdMob) {
          final ok = await AdMobService.loadAppOpen();
          if (ok) { await AdMobService.showAppOpenAndWait(); break; }
        }
        if (AdNetworkConfig.canUseMeta) {
          await MetaAdsService.showInterstitialAndWait();
        }
    }

    _preloadAll();
  }

  // ── Rewarded (avec gate) ──────────────────────────────────────────────────
  static Future<void> showRewarded({required VoidCallback onReward}) async {
    if (!_isInitialized) await initialize();

    var rewardGranted = false;
    void grantOnce() {
      if (rewardGranted) return;
      rewardGranted = true;
      onReward();
    }

    final turn = await _nextTurn();

    switch (turn % 6) {
      case 0: // Meta Rewarded → Unity fallback
        if (AdNetworkConfig.canUseMeta) {
          final ok = await MetaAdsService.loadRewarded();
          if (ok) { await MetaAdsService.showRewardedAndWait(onReward: grantOnce); break; }
        }
        await _showUnityRewardedAndWait(onReward: grantOnce);
      case 1: // Unity Rewarded → Meta fallback
        final ok = await _loadUnityRewarded();
        if (ok) {
          await _showUnityRewardedAndWait(onReward: grantOnce);
        } else if (AdNetworkConfig.canUseMeta) {
          await MetaAdsService.showRewardedAndWait(onReward: grantOnce);
        }
      case 2: // AdMob RewardedInterstitial → Meta fallback
        if (AdNetworkConfig.canUseAdMob) {
          final ok = await AdMobService.loadRewardedInterstitial();
          if (ok) { await AdMobService.showRewardedInterstitialAndWait(onReward: grantOnce); break; }
        }
        await _showUnityRewardedAndWait(onReward: grantOnce);
      case 3: // Meta Rewarded → AdMob fallback
        if (AdNetworkConfig.canUseMeta) {
          final ok = await MetaAdsService.loadRewarded();
          if (ok) { await MetaAdsService.showRewardedAndWait(onReward: grantOnce); break; }
        }
        if (AdNetworkConfig.canUseAdMob) {
          await AdMobService.showRewardedAndWait(onReward: grantOnce);
        }
      case 4: // Unity Rewarded → AdMob fallback
        final ok2 = await _loadUnityRewarded();
        if (ok2) {
          await _showUnityRewardedAndWait(onReward: grantOnce);
        } else if (AdNetworkConfig.canUseAdMob) {
          await AdMobService.showRewardedAndWait(onReward: grantOnce);
        }
      case 5: // AdMob Rewarded → Unity fallback
        if (AdNetworkConfig.canUseAdMob) {
          final ok = await AdMobService.loadRewarded();
          if (ok) { await AdMobService.showRewardedAndWait(onReward: grantOnce); break; }
        }
        await _showUnityRewardedAndWait(onReward: grantOnce);
    }

    _preloadAll();
  }

  // ── App Open ──────────────────────────────────────────────────────────────
  static Future<void> showAppOpen() async {
    if (!_isInitialized) await initialize();
    if (AdNetworkConfig.canUseAdMob) {
      final ok = await AdMobService.loadAppOpen();
      if (ok) { await AdMobService.showAppOpenAndWait(); return; }
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
    await completer.future.timeout(AdNetworkConfig.adLoadTimeout, onTimeout: () {
      print('⚠️ Unity Ads init timeout');
    });
  }

  // ── Unity Load ────────────────────────────────────────────────────────────
  static Future<bool> _loadUnityInterstitial() async {
    if (!_isInitialized) await initialize();
    if (!_isUnityInitialized) return false;
    if (_isUnityInterstitialLoaded) return true;
    if (_unityInterstitialLoadCompleter != null) return _unityInterstitialLoadCompleter!.future;

    final completer = Completer<bool>();
    _unityInterstitialLoadCompleter = completer;

    UnityAds.load(
      placementId: _unityInterstitialId,
      onComplete: (id) {
        _isUnityInterstitialLoaded = true;
        if (identical(_unityInterstitialLoadCompleter, completer)) _unityInterstitialLoadCompleter = null;
        print('✅ Unity Interstitial loaded');
        if (!completer.isCompleted) completer.complete(true);
      },
      onFailed: (id, error, message) {
        _isUnityInterstitialLoaded = false;
        if (identical(_unityInterstitialLoadCompleter, completer)) _unityInterstitialLoadCompleter = null;
        print('❌ Unity Interstitial load failed: $error - $message');
        if (!completer.isCompleted) completer.complete(false);
      },
    );

    return completer.future.timeout(AdNetworkConfig.adLoadTimeout, onTimeout: () {
      if (identical(_unityInterstitialLoadCompleter, completer)) _unityInterstitialLoadCompleter = null;
      if (!completer.isCompleted) completer.complete(false);
      print('⚠️ Unity Interstitial load timeout');
      return false;
    });
  }

  static Future<bool> _loadUnityRewarded() async {
    if (!_isInitialized) await initialize();
    if (!_isUnityInitialized) return false;
    if (_isUnityRewardedLoaded) return true;
    if (_unityRewardedLoadCompleter != null) return _unityRewardedLoadCompleter!.future;

    final completer = Completer<bool>();
    _unityRewardedLoadCompleter = completer;

    UnityAds.load(
      placementId: _unityRewardedId,
      onComplete: (id) {
        _isUnityRewardedLoaded = true;
        if (identical(_unityRewardedLoadCompleter, completer)) _unityRewardedLoadCompleter = null;
        print('✅ Unity Rewarded loaded');
        if (!completer.isCompleted) completer.complete(true);
      },
      onFailed: (id, error, message) {
        _isUnityRewardedLoaded = false;
        if (identical(_unityRewardedLoadCompleter, completer)) _unityRewardedLoadCompleter = null;
        print('❌ Unity Rewarded load failed: $error - $message');
        if (!completer.isCompleted) completer.complete(false);
      },
    );

    return completer.future.timeout(AdNetworkConfig.adLoadTimeout, onTimeout: () {
      if (identical(_unityRewardedLoadCompleter, completer)) _unityRewardedLoadCompleter = null;
      if (!completer.isCompleted) completer.complete(false);
      print('⚠️ Unity Rewarded load timeout');
      return false;
    });
  }

  // ── Unity Show ────────────────────────────────────────────────────────────
  static Future<void> _showUnityInterstitialAndWait() async {
    if (!_isUnityInterstitialLoaded) await _loadUnityInterstitial();
    if (!_isUnityInterstitialLoaded) { print('⚠️ Unity Interstitial not ready'); return; }

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
    await completer.future.timeout(const Duration(minutes: 2), onTimeout: () {
      print('⚠️ Unity Interstitial show timeout');
    });
  }

  static Future<void> _showUnityRewardedAndWait({required VoidCallback onReward}) async {
    if (!_isUnityRewardedLoaded) await _loadUnityRewarded();
    if (!_isUnityRewardedLoaded) { print('⚠️ Unity Rewarded not ready'); return; }

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
    await completer.future.timeout(const Duration(minutes: 2), onTimeout: () {
      print('⚠️ Unity Rewarded show timeout');
    });
  }

  // ── Getters publics ───────────────────────────────────────────────────────
  static bool get isInterstitialReady => _isUnityInterstitialLoaded;
  static bool get isRewardedReady => _isUnityRewardedLoaded;
  static Future<bool> loadInterstitial() => _loadUnityInterstitial();
  static Future<bool> loadRewarded() => _loadUnityRewarded();
}
