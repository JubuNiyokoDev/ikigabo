import 'dart:async';
import 'dart:ui';
import 'package:flutter/services.dart';
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

  static Future<void> initialize() async {
    if (_isInitialized) return;

    await UnityAds.init(
      gameId: _gameId,
      testMode: AdNetworkConfig.isUnityTestMode,
      onComplete: () {
        _isUnityInitialized = true;
        const mode = AdNetworkConfig.isUnityTestMode ? 'TEST' : 'PRODUCTION';
        print('✅ Unity Ads initialized ($mode)');
      },
      onFailed: (error, message) {
        print('❌ Unity Ads init failed: $error - $message');
      },
    );

    await AdMobService.initialize();

    _isInitialized = true;
  }

  /// Affiche les interstitielles des deux réseaux (Unity puis AdMob)
  static Future<void> showInterstitial() async {
    if (!_isInitialized) await initialize();

    await _showUnityInterstitialAndWait();
    await _showAdMobInterstitialIfReady();
  }

  /// Affiche les rewarded des deux réseaux (Unity puis AdMob)
  static Future<void> showRewarded({required VoidCallback onReward}) async {
    if (!_isInitialized) await initialize();

    await _showUnityRewardedAndWait(onReward: onReward);
    await _showAdMobRewardedIfReady(onReward: onReward);
  }

  // -- Unity Interstitial (attends la fin) --
  static Future<void> _showUnityInterstitialAndWait() async {
    if (!_isInterstitialLoaded) {
      await loadInterstitial();
      await Future.delayed(const Duration(milliseconds: 500));
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
        if (!completer.isCompleted) completer.complete();
      },
      onComplete: (placementId) {
        print('✅ Unity Interstitial completed');
        _isInterstitialLoaded = false;
        if (!completer.isCompleted) completer.complete();
      },
      onFailed: (placementId, error, message) {
        print('❌ Unity Interstitial failed: $error - $message');
        _isInterstitialLoaded = false;
        if (!completer.isCompleted) completer.complete();
      },
    );

    await completer.future;
  }

  // -- AdMob Interstitial (attends la fin) --
  static Future<void> _showAdMobInterstitialIfReady() async {
    if (AdMobService.isInterstitialReady) {
      await AdMobService.showInterstitialAndWait();
    }
  }

  // -- Unity Rewarded (attends la fin) --
  static Future<void> _showUnityRewardedAndWait({
    required VoidCallback onReward,
  }) async {
    if (!_isRewardedLoaded) {
      await loadRewarded();
      await Future.delayed(const Duration(milliseconds: 500));
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
        if (!completer.isCompleted) completer.complete();
      },
      onComplete: (placementId) {
        print('🎁 Unity Reward granted');
        onReward();
        _isRewardedLoaded = false;
        if (!completer.isCompleted) completer.complete();
      },
      onFailed: (placementId, error, message) {
        print('❌ Unity Rewarded failed: $error - $message');
        _isRewardedLoaded = false;
        if (!completer.isCompleted) completer.complete();
      },
    );

    await completer.future;
  }

  // -- AdMob Rewarded (attends la fin) --
  static Future<void> _showAdMobRewardedIfReady({
    required VoidCallback onReward,
  }) async {
    if (AdMobService.isRewardedReady) {
      await AdMobService.showRewardedAndWait(onReward: onReward);
    }
  }

  // -- Load --
  static Future<void> loadInterstitial() async {
    if (!_isInitialized) await initialize();
    if (!_isUnityInitialized || _isInterstitialLoaded) return;

    await UnityAds.load(
      placementId: _interstitialAdUnitId,
      onComplete: (placementId) {
        _isInterstitialLoaded = true;
        print('✅ Interstitial loaded');
      },
      onFailed: (placementId, error, message) {
        _isInterstitialLoaded = false;
        print('❌ Interstitial load failed: $error - $message');
      },
    );
  }

  static Future<void> loadRewarded() async {
    if (!_isInitialized) await initialize();
    if (!_isUnityInitialized || _isRewardedLoaded) return;

    await UnityAds.load(
      placementId: _rewardedAdUnitId,
      onComplete: (placementId) {
        _isRewardedLoaded = true;
        print('✅ Rewarded loaded');
      },
      onFailed: (placementId, error, message) {
        _isRewardedLoaded = false;
        print('❌ Rewarded load failed: $error - $message');
      },
    );
  }

  static bool get isInterstitialReady => _isInterstitialLoaded;
  static bool get isRewardedReady => _isRewardedLoaded;
}
