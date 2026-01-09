import 'dart:ui';
import 'package:unity_ads_plugin/unity_ads_plugin.dart';
import 'package:flutter/services.dart';

class AdsService {
  // 🔑 IDs UNITY
  static const String _gameId = '6021741'; // Android Game ID
  static const String _interstitialAdUnitId = 'Interstitial_Android';
  static const String _rewardedAdUnitId = 'Rewarded_Android';

  static bool _isInitialized = false;
  static bool _isInterstitialLoaded = false;
  static bool _isRewardedLoaded = false;

  // 🔹 INIT UNITY ADS
  static Future<void> initialize() async {
    if (_isInitialized) return;

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

  // 🔹 SHOW INTERSTITIAL
  static Future<void> showInterstitial() async {
    if (!_isInitialized) await initialize();

    if (!_isInterstitialLoaded) {
      await loadInterstitial();
      await Future.delayed(const Duration(milliseconds: 500));
    }

    if (!_isInterstitialLoaded) {
      print('⚠️ Interstitial not ready');
      return;
    }

    UnityAds.showVideoAd(
      placementId: _interstitialAdUnitId,
      onStart: (placementId) => print('▶ Interstitial started'),
      onClick: (placementId) => print('🖱 Interstitial clicked - Revenue!'),
      onComplete: (placementId) {
        print('✅ Interstitial completed');
        _isInterstitialLoaded = false;
      },
      onFailed: (placementId, error, message) {
        print('❌ Interstitial failed: $error - $message');
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

  // 🔹 SHOW REWARDED
  static Future<void> showRewarded({required VoidCallback onReward}) async {
    if (!_isInitialized) await initialize();

    if (!_isRewardedLoaded) {
      await loadRewarded();
      await Future.delayed(const Duration(milliseconds: 500));
    }

    if (!_isRewardedLoaded) {
      print('⚠️ Rewarded not ready');
      return;
    }

    UnityAds.showVideoAd(
      placementId: _rewardedAdUnitId,
      onComplete: (placementId) {
        print('🎁 Reward granted');
        onReward();
        _isRewardedLoaded = false;
      },
      onFailed: (placementId, error, message) {
        print('❌ Rewarded failed: $error - $message');
        _isRewardedLoaded = false;
      },
    );
  }

  static bool get isInterstitialReady => _isInterstitialLoaded;
  static bool get isRewardedReady => _isRewardedLoaded;
}