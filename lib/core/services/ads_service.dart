import 'dart:async';
import 'dart:ui';
import 'package:unity_ads_plugin/unity_ads_plugin.dart';
import 'ad_network_config.dart';
import 'admob_service.dart';

class AdsService {
  static const String _gameId = '6021741';
  static const String _interstitialAdUnitId = 'Interstitial_Android';
  static const String _rewardedAdUnitId = 'Rewarded_Android';

  static bool _isInitialized = false;
  static bool _isUnityInitialized = false;
  static bool _isInterstitialLoaded = false;
  static bool _isRewardedLoaded = false;
  static Completer<void>? _initializeCompleter;
  static Completer<bool>? _interstitialLoadCompleter;
  static Completer<bool>? _rewardedLoadCompleter;

  static Future<void> initialize() async {
    if (_isInitialized) return;
    if (_initializeCompleter != null) {
      return _initializeCompleter!.future;
    }

    final completer = Completer<void>();
    _initializeCompleter = completer;

    try {
      await _initializeUnity();

      if (AdNetworkConfig.canUseAdMob) {
        await AdMobService.initialize();
      }

      _isInitialized = true;
      _preloadFullScreenAds();
    } finally {
      if (!completer.isCompleted) completer.complete();
      _initializeCompleter = null;
    }
  }

  /// Affiche une interstitielle sur le réseau principal, puis tente le fallback.
  static Future<void> showInterstitial() async {
    if (!_isInitialized) await initialize();

    if (AdNetworkConfig.fullScreenPrimaryNetwork == AdNetwork.admob &&
        AdNetworkConfig.canUseAdMob) {
      final adMobLoaded = await AdMobService.loadInterstitial();
      if (adMobLoaded) {
        await AdMobService.showInterstitialAndWait();
      } else {
        await _showUnityInterstitialAndWait();
      }
    } else {
      final unityLoaded = await loadInterstitial();
      if (unityLoaded) {
        await _showUnityInterstitialAndWait();
      } else if (AdNetworkConfig.canUseAdMob) {
        await AdMobService.showInterstitialAndWait();
      }
    }
    _preloadFullScreenAds();
  }

  /// Affiche une rewarded sur le réseau principal, puis tente le fallback.
  static Future<void> showRewarded({required VoidCallback onReward}) async {
    if (!_isInitialized) await initialize();

    var rewardGranted = false;
    void grantRewardOnce() {
      if (rewardGranted) return;
      rewardGranted = true;
      onReward();
    }

    if (AdNetworkConfig.fullScreenPrimaryNetwork == AdNetwork.admob &&
        AdNetworkConfig.canUseAdMob) {
      final adMobLoaded = await AdMobService.loadRewarded();
      if (adMobLoaded) {
        await AdMobService.showRewardedAndWait(onReward: grantRewardOnce);
      } else {
        await _showUnityRewardedAndWait(onReward: grantRewardOnce);
      }
    } else {
      final unityLoaded = await loadRewarded();
      if (unityLoaded) {
        await _showUnityRewardedAndWait(onReward: grantRewardOnce);
      } else if (AdNetworkConfig.canUseAdMob) {
        await AdMobService.showRewardedAndWait(onReward: grantRewardOnce);
      }
    }
    _preloadFullScreenAds();
  }

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

  static void _preloadFullScreenAds() {
    unawaited(loadInterstitial());
    unawaited(loadRewarded());
    if (AdNetworkConfig.canUseAdMob) {
      unawaited(AdMobService.loadInterstitial());
      unawaited(AdMobService.loadRewarded());
    }
  }

  // -- Unity Interstitial (attends la fin) --
  static Future<void> _showUnityInterstitialAndWait() async {
    if (!_isInterstitialLoaded) {
      await loadInterstitial();
    }

    if (!_isInterstitialLoaded) {
      print('⚠️ Unity Interstitial not ready');
      return;
    }

    final completer = Completer<void>();

    UnityAds.showVideoAd(
      placementId: _interstitialAdUnitId,
      onStart: (placementId) => print('▶ Unity Interstitial started'),
      onClick: (placementId) => print('🖱 Unity Interstitial clicked'),
      onSkipped: (placementId) {
        print('⏭ Unity Interstitial skipped');
        _isInterstitialLoaded = false;
        unawaited(loadInterstitial());
        if (!completer.isCompleted) completer.complete();
      },
      onComplete: (placementId) {
        print('✅ Unity Interstitial completed');
        _isInterstitialLoaded = false;
        unawaited(loadInterstitial());
        if (!completer.isCompleted) completer.complete();
      },
      onFailed: (placementId, error, message) {
        print('❌ Unity Interstitial failed: $error - $message');
        _isInterstitialLoaded = false;
        unawaited(loadInterstitial());
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

  // -- Unity Rewarded (attends la fin) --
  static Future<void> _showUnityRewardedAndWait({
    required VoidCallback onReward,
  }) async {
    if (!_isRewardedLoaded) {
      await loadRewarded();
    }

    if (!_isRewardedLoaded) {
      print('⚠️ Unity Rewarded not ready');
      return;
    }

    final completer = Completer<void>();

    UnityAds.showVideoAd(
      placementId: _rewardedAdUnitId,
      onStart: (placementId) => print('▶ Unity Rewarded started'),
      onClick: (placementId) => print('🖱 Unity Rewarded clicked'),
      onSkipped: (placementId) {
        print('⏭ Unity Rewarded skipped');
        _isRewardedLoaded = false;
        unawaited(loadRewarded());
        if (!completer.isCompleted) completer.complete();
      },
      onComplete: (placementId) {
        print('🎁 Unity Reward granted');
        onReward();
        _isRewardedLoaded = false;
        unawaited(loadRewarded());
        if (!completer.isCompleted) completer.complete();
      },
      onFailed: (placementId, error, message) {
        print('❌ Unity Rewarded failed: $error - $message');
        _isRewardedLoaded = false;
        unawaited(loadRewarded());
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

  // -- Load --
  static Future<bool> loadInterstitial() async {
    if (!_isInitialized) await initialize();
    if (!_isUnityInitialized) return false;
    if (_isInterstitialLoaded) return true;
    if (_interstitialLoadCompleter != null) {
      return _interstitialLoadCompleter!.future;
    }

    final completer = Completer<bool>();
    _interstitialLoadCompleter = completer;

    UnityAds.load(
      placementId: _interstitialAdUnitId,
      onComplete: (placementId) {
        _isInterstitialLoaded = true;
        if (identical(_interstitialLoadCompleter, completer)) {
          _interstitialLoadCompleter = null;
        }
        print('✅ Unity Interstitial loaded');
        if (!completer.isCompleted) completer.complete(true);
      },
      onFailed: (placementId, error, message) {
        _isInterstitialLoaded = false;
        if (identical(_interstitialLoadCompleter, completer)) {
          _interstitialLoadCompleter = null;
        }
        print('❌ Unity Interstitial load failed: $error - $message');
        if (!completer.isCompleted) completer.complete(false);
      },
    );

    return completer.future.timeout(
      AdNetworkConfig.adLoadTimeout,
      onTimeout: () {
        if (identical(_interstitialLoadCompleter, completer)) {
          _interstitialLoadCompleter = null;
        }
        if (!completer.isCompleted) completer.complete(false);
        print('⚠️ Unity Interstitial load timeout');
        return false;
      },
    );
  }

  static Future<bool> loadRewarded() async {
    if (!_isInitialized) await initialize();
    if (!_isUnityInitialized) return false;
    if (_isRewardedLoaded) return true;
    if (_rewardedLoadCompleter != null) {
      return _rewardedLoadCompleter!.future;
    }

    final completer = Completer<bool>();
    _rewardedLoadCompleter = completer;

    UnityAds.load(
      placementId: _rewardedAdUnitId,
      onComplete: (placementId) {
        _isRewardedLoaded = true;
        if (identical(_rewardedLoadCompleter, completer)) {
          _rewardedLoadCompleter = null;
        }
        print('✅ Unity Rewarded loaded');
        if (!completer.isCompleted) completer.complete(true);
      },
      onFailed: (placementId, error, message) {
        _isRewardedLoaded = false;
        if (identical(_rewardedLoadCompleter, completer)) {
          _rewardedLoadCompleter = null;
        }
        print('❌ Unity Rewarded load failed: $error - $message');
        if (!completer.isCompleted) completer.complete(false);
      },
    );

    return completer.future.timeout(
      AdNetworkConfig.adLoadTimeout,
      onTimeout: () {
        if (identical(_rewardedLoadCompleter, completer)) {
          _rewardedLoadCompleter = null;
        }
        if (!completer.isCompleted) completer.complete(false);
        print('⚠️ Unity Rewarded load timeout');
        return false;
      },
    );
  }

  static bool get isInterstitialReady => _isInterstitialLoaded;
  static bool get isRewardedReady => _isRewardedLoaded;
}
