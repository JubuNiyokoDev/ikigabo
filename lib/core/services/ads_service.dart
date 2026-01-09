import 'dart:ui';
import 'package:unity_ads_plugin/unity_ads_plugin.dart';

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
      testMode: false, // ✅ PRODUCTION MODE - Vraies publicités
      onComplete: () {
        _isInitialized = true;
        print('✅ Unity Ads initialized (PRODUCTION)');
        // NE PAS charger automatiquement les ads
      },
      onFailed: (error, message) {
        print('❌ Unity Ads init failed: $error - $message');
      },
    );
  }

  // 🔹 LOAD INTERSTITIAL (seulement quand nécessaire)
  static Future<void> loadInterstitial() async {
    if (!_isInitialized) await initialize();
    if (_isInterstitialLoaded) return; // Éviter de recharger si déjà chargé

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

  // 🔹 SHOW INTERSTITIAL (seulement sur demande explicite)
  static Future<void> showInterstitial() async {
    if (!_isInitialized) await initialize();

    // Charger si pas encore fait
    if (!_isInterstitialLoaded) {
      await loadInterstitial();
      // Attendre un peu que l'ad se charge
      await Future.delayed(const Duration(seconds: 2));
    }

    if (!_isInterstitialLoaded) {
      print('⚠️ Interstitial not ready');
      return;
    }

    UnityAds.showVideoAd(
      placementId: _interstitialAdUnitId,
      onStart: (placementId) => print('▶ Interstitial started'),
      onClick: (placementId) => print('🖱 Interstitial clicked'),
      onComplete: (placementId) {
        print('✅ Interstitial completed');
        _isInterstitialLoaded = false;
        // NE PAS recharger automatiquement
      },
      onFailed: (placementId, error, message) {
        print('❌ Interstitial failed: $error - $message');
        _isInterstitialLoaded = false;
      },
    );
  }

  // 🔹 LOAD REWARDED (seulement quand nécessaire)
  static Future<void> loadRewarded() async {
    if (!_isInitialized) await initialize();
    if (_isRewardedLoaded) return; // Éviter de recharger si déjà chargé

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

  // 🔹 SHOW REWARDED (seulement sur demande explicite)
  static Future<void> showRewarded({required VoidCallback onReward}) async {
    if (!_isInitialized) await initialize();

    // Charger si pas encore fait
    if (!_isRewardedLoaded) {
      await loadRewarded();
      // Attendre un peu que l'ad se charge
      await Future.delayed(const Duration(seconds: 2));
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
        // NE PAS recharger automatiquement
      },
      onFailed: (placementId, error, message) {
        print('❌ Rewarded failed: $error - $message');
        _isRewardedLoaded = false;
      },
    );
  }

  // 🔹 Vérifier si les ads sont prêtes
  static bool get isInterstitialReady => _isInterstitialLoaded;
  static bool get isRewardedReady => _isRewardedLoaded;
}
