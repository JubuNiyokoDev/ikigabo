import 'dart:ui';
import 'package:unity_ads_plugin/unity_ads_plugin.dart';
import 'package:flutter/services.dart';
import 'admob_service.dart';
import 'dart:math';

class AdsService {
  // 🔑 IDs UNITY
  static const String _gameId = '6021741'; // Android Game ID
  static const String _interstitialAdUnitId = 'Interstitial_Android';
  static const String _rewardedAdUnitId = 'Rewarded_Android';

  static bool _isInitialized = false;
  static bool _isInterstitialLoaded = false;
  static bool _isRewardedLoaded = false;
  static final Random _random = Random();

  // 🔹 INIT BOTH ADS
  static Future<void> initialize() async {
    if (_isInitialized) return;

    // Init Unity
    await UnityAds.init(
      gameId: _gameId,
      testMode: false,
      onComplete: () {
        _isInitialized = true;
        print('✅ Unity Ads initialized (PRODUCTION)');
      },
      onFailed: (error, message) {
        print('❌ Unity Ads init failed: $error - $message');
      },
    );

    // Init AdMob
    await AdMobService.initialize();
  }

  // 🔹 SHOW INTERSTITIAL (ALTERNANCE 50/50)
  static Future<void> showInterstitial() async {
    if (!_isInitialized) await initialize();

    // Alternance 50/50 entre Unity et AdMob
    final useUnity = _random.nextBool();
    
    if (useUnity) {
      print('🎯 Tentative Unity Interstitial');
      await _showUnityInterstitial();
    } else {
      print('🎯 Tentative AdMob Interstitial');
      await AdMobService.showInterstitial();
    }
  }

  // 🔹 SHOW REWARDED (ALTERNANCE 50/50)
  static Future<void> showRewarded({required VoidCallback onReward}) async {
    if (!_isInitialized) await initialize();

    // Alternance 50/50 entre Unity et AdMob
    final useUnity = _random.nextBool();
    
    if (useUnity) {
      print('🎯 Tentative Unity Rewarded');
      await _showUnityRewarded(onReward: onReward);
    } else {
      print('🎯 Tentative AdMob Rewarded');
      await AdMobService.showRewarded(onReward: onReward);
    }
  }

  // 🔹 LOAD INTERSTITIAL
  static Future<void> loadInterstitial() async {
    if (!_isInitialized) await initialize();
    if (_isInterstitialLoaded) return;

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

  // 🔹 UNITY INTERSTITIAL (PRIVATE)
  static Future<void> _showUnityInterstitial() async {

    if (!_isInterstitialLoaded) {
      await loadInterstitial();
      await Future.delayed(const Duration(milliseconds: 500));
    }

    if (!_isInterstitialLoaded) {
      print('⚠️ Unity Interstitial not ready');
      return;
    }

    UnityAds.showVideoAd(
      placementId: _interstitialAdUnitId,
      onStart: (placementId) => print('▶ Unity Interstitial started'),
      onClick: (placementId) => print('🖱 Unity Interstitial clicked - Revenue!'),
      onSkipped: (placementId) => print('⏭ Unity Interstitial skipped'),
      onComplete: (placementId) {
        print('✅ Unity Interstitial completed');
        _isInterstitialLoaded = false;
      },
      onFailed: (placementId, error, message) {
        print('❌ Unity Interstitial failed: $error - $message');
        _isInterstitialLoaded = false;
      },
    );
  }

  // 🔹 LOAD REWARDED
  static Future<void> loadRewarded() async {
    if (!_isInitialized) await initialize();
    if (_isRewardedLoaded) return;

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

  // 🔹 UNITY REWARDED (PRIVATE)
  static Future<void> _showUnityRewarded({required VoidCallback onReward}) async {

    if (!_isRewardedLoaded) {
      await loadRewarded();
      await Future.delayed(const Duration(milliseconds: 500));
    }

    if (!_isRewardedLoaded) {
      print('⚠️ Unity Rewarded not ready');
      return;
    }

    UnityAds.showVideoAd(
      placementId: _rewardedAdUnitId,
      onComplete: (placementId) {
        print('🎁 Unity Reward granted');
        onReward();
        _isRewardedLoaded = false;
      },
      onFailed: (placementId, error, message) {
        print('❌ Unity Rewarded failed: $error - $message');
        _isRewardedLoaded = false;
      },
    );
  }

  static bool get isInterstitialReady => _isInterstitialLoaded;
  static bool get isRewardedReady => _isRewardedLoaded;
}