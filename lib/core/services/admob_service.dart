import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'ad_network_config.dart';

class AdMobService {
  static const String _liveBannerAdUnitId =
      'ca-app-pub-2300546388710165/5022166817';
  static const String _liveInterstitialAdUnitId =
      'ca-app-pub-2300546388710165/3121943541';
  static const String _liveRewardedAdUnitId =
      'ca-app-pub-2300546388710165/8111364581';

  static const String _testBannerAdUnitId =
      'ca-app-pub-3940256099942544/6300978111';
  static const String _testInterstitialAdUnitId =
      'ca-app-pub-3940256099942544/1033173712';
  static const String _testRewardedAdUnitId =
      'ca-app-pub-3940256099942544/5224354917';

  static bool _isInitialized = false;
  static InterstitialAd? _interstitialAd;
  static RewardedAd? _rewardedAd;
  static Completer<bool>? _interstitialLoadCompleter;
  static Completer<bool>? _rewardedLoadCompleter;

  static Future<void> initialize() async {
    if (_isInitialized) return;
    if (!AdNetworkConfig.canUseAdMob) return;

    if (AdNetworkConfig.useTestAds) {
      await MobileAds.instance.updateRequestConfiguration(
        RequestConfiguration(testDeviceIds: AdNetworkConfig.adMobTestDeviceIds),
      );
    }

    await MobileAds.instance.initialize();
    _isInitialized = true;
    print('✅ AdMob initialized ($_modeLabel)');

    unawaited(loadInterstitial());
    unawaited(loadRewarded());
  }

  static String get _bannerAdUnitId =>
      AdNetworkConfig.useTestAds ? _testBannerAdUnitId : _liveBannerAdUnitId;

  static String get _interstitialAdUnitId => AdNetworkConfig.useTestAds
      ? _testInterstitialAdUnitId
      : _liveInterstitialAdUnitId;

  static String get _rewardedAdUnitId => AdNetworkConfig.useTestAds
      ? _testRewardedAdUnitId
      : _liveRewardedAdUnitId;

  static String get _modeLabel =>
      AdNetworkConfig.useTestAds ? 'TEST' : 'PRODUCTION';

  static Future<bool> loadInterstitial({bool force = false}) async {
    if (!AdNetworkConfig.canUseAdMob) return false;
    if (!_isInitialized) await initialize();
    if (!_isInitialized) return false;
    if (_interstitialAd != null && !force) return true;
    if (_interstitialLoadCompleter != null) {
      return _interstitialLoadCompleter!.future;
    }

    if (force) {
      _interstitialAd?.dispose();
      _interstitialAd = null;
    }

    final completer = Completer<bool>();
    _interstitialLoadCompleter = completer;

    InterstitialAd.load(
      adUnitId: _interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd?.dispose();
          _interstitialAd = ad;
          print('✅ AdMob Interstitial loaded ($_modeLabel)');
          if (identical(_interstitialLoadCompleter, completer)) {
            _interstitialLoadCompleter = null;
          }
          if (!completer.isCompleted) completer.complete(true);
        },
        onAdFailedToLoad: (error) {
          print('❌ AdMob Interstitial failed: $error');
          _interstitialAd = null;
          if (identical(_interstitialLoadCompleter, completer)) {
            _interstitialLoadCompleter = null;
          }
          if (!completer.isCompleted) completer.complete(false);
        },
      ),
    );

    return completer.future.timeout(
      AdNetworkConfig.adLoadTimeout,
      onTimeout: () {
        if (identical(_interstitialLoadCompleter, completer)) {
          _interstitialLoadCompleter = null;
        }
        if (!completer.isCompleted) completer.complete(false);
        print('⚠️ AdMob Interstitial load timeout');
        return false;
      },
    );
  }

  static Future<void> showInterstitial() async {
    await showInterstitialAndWait();
  }

  static Future<void> showInterstitialAndWait() async {
    if (_interstitialAd == null) {
      final loaded = await loadInterstitial();
      if (!loaded || _interstitialAd == null) {
        print('⚠️ AdMob Interstitial not ready');
        return;
      }
    }

    final completer = Completer<void>();
    final ad = _interstitialAd!;
    _interstitialAd = null;

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        print('▶ AdMob Interstitial started');
      },
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        unawaited(loadInterstitial());
        print('✅ AdMob Interstitial dismissed');
        if (!completer.isCompleted) completer.complete();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        unawaited(loadInterstitial(force: true));
        print('❌ AdMob Interstitial show failed: $error');
        if (!completer.isCompleted) completer.complete();
      },
    );

    try {
      await ad.show();
    } catch (error) {
      ad.dispose();
      unawaited(loadInterstitial(force: true));
      print('❌ AdMob Interstitial show threw: $error');
      if (!completer.isCompleted) completer.complete();
    }

    await completer.future.timeout(
      const Duration(minutes: 2),
      onTimeout: () {
        print('⚠️ AdMob Interstitial show timeout');
      },
    );
  }

  static Future<bool> loadRewarded({bool force = false}) async {
    if (!AdNetworkConfig.canUseAdMob) return false;
    if (!_isInitialized) await initialize();
    if (!_isInitialized) return false;
    if (_rewardedAd != null && !force) return true;
    if (_rewardedLoadCompleter != null) {
      return _rewardedLoadCompleter!.future;
    }

    if (force) {
      _rewardedAd?.dispose();
      _rewardedAd = null;
    }

    final completer = Completer<bool>();
    _rewardedLoadCompleter = completer;

    RewardedAd.load(
      adUnitId: _rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd?.dispose();
          _rewardedAd = ad;
          print('✅ AdMob Rewarded loaded ($_modeLabel)');
          if (identical(_rewardedLoadCompleter, completer)) {
            _rewardedLoadCompleter = null;
          }
          if (!completer.isCompleted) completer.complete(true);
        },
        onAdFailedToLoad: (error) {
          print('❌ AdMob Rewarded failed: $error');
          _rewardedAd = null;
          if (identical(_rewardedLoadCompleter, completer)) {
            _rewardedLoadCompleter = null;
          }
          if (!completer.isCompleted) completer.complete(false);
        },
      ),
    );

    return completer.future.timeout(
      AdNetworkConfig.adLoadTimeout,
      onTimeout: () {
        if (identical(_rewardedLoadCompleter, completer)) {
          _rewardedLoadCompleter = null;
        }
        if (!completer.isCompleted) completer.complete(false);
        print('⚠️ AdMob Rewarded load timeout');
        return false;
      },
    );
  }

  static Future<void> showRewarded({required VoidCallback onReward}) async {
    await showRewardedAndWait(onReward: onReward);
  }

  static Future<void> showRewardedAndWait({
    required VoidCallback onReward,
  }) async {
    if (_rewardedAd == null) {
      final loaded = await loadRewarded();
      if (!loaded || _rewardedAd == null) {
        print('⚠️ AdMob Rewarded not ready');
        return;
      }
    }

    final completer = Completer<void>();
    final ad = _rewardedAd!;
    _rewardedAd = null;

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        print('▶ AdMob Rewarded started');
      },
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        unawaited(loadRewarded());
        print('✅ AdMob Rewarded dismissed');
        if (!completer.isCompleted) completer.complete();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        unawaited(loadRewarded(force: true));
        print('❌ AdMob Rewarded show failed: $error');
        if (!completer.isCompleted) completer.complete();
      },
    );

    try {
      await ad.show(
        onUserEarnedReward: (ad, reward) {
          print('🎁 AdMob Reward earned: ${reward.amount} ${reward.type}');
          onReward();
        },
      );
    } catch (error) {
      ad.dispose();
      unawaited(loadRewarded(force: true));
      print('❌ AdMob Rewarded show threw: $error');
      if (!completer.isCompleted) completer.complete();
    }

    await completer.future.timeout(
      const Duration(minutes: 2),
      onTimeout: () {
        print('⚠️ AdMob Rewarded show timeout');
      },
    );
  }

  static BannerAd createBanner({
    VoidCallback? onLoaded,
    void Function(LoadAdError error)? onFailedToLoad,
  }) {
    return BannerAd(
      adUnitId: _bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          print('✅ AdMob Banner loaded ($_modeLabel)');
          onLoaded?.call();
        },
        onAdFailedToLoad: (ad, error) {
          print('❌ AdMob Banner failed: $error');
          ad.dispose();
          onFailedToLoad?.call(error);
        },
      ),
    );
  }

  static bool get isInterstitialReady => _interstitialAd != null;
  static bool get isRewardedReady => _rewardedAd != null;

  static void dispose() {
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
  }
}
