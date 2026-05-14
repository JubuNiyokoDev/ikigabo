import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'ad_network_config.dart';

class AdMobService {
  // ── Live IDs ──────────────────────────────────────────────────────────────
  static const String _liveBannerAdUnitId =
      'ca-app-pub-2300546388710165/5022166817';
  static const String _liveInterstitialAdUnitId =
      'ca-app-pub-2300546388710165/3121943541';
  static const String _liveRewardedAdUnitId =
      'ca-app-pub-2300546388710165/8111364581';
  static const String _liveAppOpenAdUnitId =
      'ca-app-pub-2300546388710165/1777072280';
  static const String _liveRewardedInterstitialAdUnitId =
      'ca-app-pub-2300546388710165/9687335987';

  // ── Test IDs ──────────────────────────────────────────────────────────────
  static const String _testBannerAdUnitId =
      'ca-app-pub-3940256099942544/6300978111';
  static const String _testInterstitialAdUnitId =
      'ca-app-pub-3940256099942544/1033173712';
  static const String _testRewardedAdUnitId =
      'ca-app-pub-3940256099942544/5224354917';
  static const String _testAppOpenAdUnitId =
      'ca-app-pub-3940256099942544/9257395921';
  static const String _testRewardedInterstitialAdUnitId =
      'ca-app-pub-3940256099942544/5354046379';

  // ── State ─────────────────────────────────────────────────────────────────
  static bool _isInitialized = false;
  static InterstitialAd? _interstitialAd;
  static RewardedAd? _rewardedAd;
  static AppOpenAd? _appOpenAd;
  static RewardedInterstitialAd? _rewardedInterstitialAd;

  static Completer<bool>? _interstitialLoadCompleter;
  static Completer<bool>? _rewardedLoadCompleter;
  static Completer<bool>? _appOpenLoadCompleter;
  static Completer<bool>? _rewardedInterstitialLoadCompleter;

  // ── ID getters ────────────────────────────────────────────────────────────
  static String get _bannerAdUnitId =>
      AdNetworkConfig.useTestAds ? _testBannerAdUnitId : _liveBannerAdUnitId;
  static String get _interstitialAdUnitId => AdNetworkConfig.useTestAds
      ? _testInterstitialAdUnitId
      : _liveInterstitialAdUnitId;
  static String get _rewardedAdUnitId =>
      AdNetworkConfig.useTestAds ? _testRewardedAdUnitId : _liveRewardedAdUnitId;
  static String get _appOpenAdUnitId =>
      AdNetworkConfig.useTestAds ? _testAppOpenAdUnitId : _liveAppOpenAdUnitId;
  static String get _rewardedInterstitialAdUnitId => AdNetworkConfig.useTestAds
      ? _testRewardedInterstitialAdUnitId
      : _liveRewardedInterstitialAdUnitId;

  static String get _modeLabel =>
      AdNetworkConfig.useTestAds ? 'TEST' : 'PRODUCTION';

  // ── Init ──────────────────────────────────────────────────────────────────
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
    unawaited(loadAppOpen());
    unawaited(loadRewardedInterstitial());
  }

  // ── Interstitial ──────────────────────────────────────────────────────────
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

    return completer.future.timeout(AdNetworkConfig.adLoadTimeout, onTimeout: () {
      if (identical(_interstitialLoadCompleter, completer)) {
        _interstitialLoadCompleter = null;
      }
      if (!completer.isCompleted) completer.complete(false);
      print('⚠️ AdMob Interstitial load timeout');
      return false;
    });
  }

  static Future<void> showInterstitial() => showInterstitialAndWait();

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
      onAdShowedFullScreenContent: (ad) => print('▶ AdMob Interstitial started'),
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

    await completer.future.timeout(const Duration(minutes: 2), onTimeout: () {
      print('⚠️ AdMob Interstitial show timeout');
    });
  }

  // ── Rewarded ──────────────────────────────────────────────────────────────
  static Future<bool> loadRewarded({bool force = false}) async {
    if (!AdNetworkConfig.canUseAdMob) return false;
    if (!_isInitialized) await initialize();
    if (!_isInitialized) return false;
    if (_rewardedAd != null && !force) return true;
    if (_rewardedLoadCompleter != null) return _rewardedLoadCompleter!.future;
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

    return completer.future.timeout(AdNetworkConfig.adLoadTimeout, onTimeout: () {
      if (identical(_rewardedLoadCompleter, completer)) {
        _rewardedLoadCompleter = null;
      }
      if (!completer.isCompleted) completer.complete(false);
      print('⚠️ AdMob Rewarded load timeout');
      return false;
    });
  }

  static Future<void> showRewarded({required VoidCallback onReward}) =>
      showRewardedAndWait(onReward: onReward);

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
      onAdShowedFullScreenContent: (ad) => print('▶ AdMob Rewarded started'),
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

    await completer.future.timeout(const Duration(minutes: 2), onTimeout: () {
      print('⚠️ AdMob Rewarded show timeout');
    });
  }

  // ── App Open Ad ───────────────────────────────────────────────────────────
  static Future<bool> loadAppOpen({bool force = false}) async {
    if (!AdNetworkConfig.canUseAdMob) return false;
    if (!_isInitialized) await initialize();
    if (!_isInitialized) return false;
    if (_appOpenAd != null && !force) return true;
    if (_appOpenLoadCompleter != null) return _appOpenLoadCompleter!.future;
    if (force) {
      _appOpenAd?.dispose();
      _appOpenAd = null;
    }

    final completer = Completer<bool>();
    _appOpenLoadCompleter = completer;

    AppOpenAd.load(
      adUnitId: _appOpenAdUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _appOpenAd?.dispose();
          _appOpenAd = ad;
          print('✅ AdMob AppOpen loaded ($_modeLabel)');
          if (identical(_appOpenLoadCompleter, completer)) {
            _appOpenLoadCompleter = null;
          }
          if (!completer.isCompleted) completer.complete(true);
        },
        onAdFailedToLoad: (error) {
          print('❌ AdMob AppOpen failed: $error');
          _appOpenAd = null;
          if (identical(_appOpenLoadCompleter, completer)) {
            _appOpenLoadCompleter = null;
          }
          if (!completer.isCompleted) completer.complete(false);
        },
      ),
    );

    return completer.future.timeout(AdNetworkConfig.adLoadTimeout, onTimeout: () {
      if (identical(_appOpenLoadCompleter, completer)) {
        _appOpenLoadCompleter = null;
      }
      if (!completer.isCompleted) completer.complete(false);
      print('⚠️ AdMob AppOpen load timeout');
      return false;
    });
  }

  static Future<void> showAppOpenAndWait() async {
    if (_appOpenAd == null) {
      final loaded = await loadAppOpen();
      if (!loaded || _appOpenAd == null) {
        print('⚠️ AdMob AppOpen not ready');
        return;
      }
    }

    final completer = Completer<void>();
    final ad = _appOpenAd!;
    _appOpenAd = null;

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) => print('▶ AdMob AppOpen started'),
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        unawaited(loadAppOpen());
        print('✅ AdMob AppOpen dismissed');
        if (!completer.isCompleted) completer.complete();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        unawaited(loadAppOpen(force: true));
        print('❌ AdMob AppOpen show failed: $error');
        if (!completer.isCompleted) completer.complete();
      },
    );

    try {
      await ad.show();
    } catch (error) {
      ad.dispose();
      unawaited(loadAppOpen(force: true));
      print('❌ AdMob AppOpen show threw: $error');
      if (!completer.isCompleted) completer.complete();
    }

    await completer.future.timeout(const Duration(minutes: 2), onTimeout: () {
      print('⚠️ AdMob AppOpen show timeout');
    });
  }

  // ── Rewarded Interstitial ─────────────────────────────────────────────────
  static Future<bool> loadRewardedInterstitial({bool force = false}) async {
    if (!AdNetworkConfig.canUseAdMob) return false;
    if (!_isInitialized) await initialize();
    if (!_isInitialized) return false;
    if (_rewardedInterstitialAd != null && !force) return true;
    if (_rewardedInterstitialLoadCompleter != null) {
      return _rewardedInterstitialLoadCompleter!.future;
    }
    if (force) {
      _rewardedInterstitialAd?.dispose();
      _rewardedInterstitialAd = null;
    }

    final completer = Completer<bool>();
    _rewardedInterstitialLoadCompleter = completer;

    RewardedInterstitialAd.load(
      adUnitId: _rewardedInterstitialAdUnitId,
      request: const AdRequest(),
      rewardedInterstitialAdLoadCallback: RewardedInterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedInterstitialAd?.dispose();
          _rewardedInterstitialAd = ad;
          print('✅ AdMob RewardedInterstitial loaded ($_modeLabel)');
          if (identical(_rewardedInterstitialLoadCompleter, completer)) {
            _rewardedInterstitialLoadCompleter = null;
          }
          if (!completer.isCompleted) completer.complete(true);
        },
        onAdFailedToLoad: (error) {
          print('❌ AdMob RewardedInterstitial failed: $error');
          _rewardedInterstitialAd = null;
          if (identical(_rewardedInterstitialLoadCompleter, completer)) {
            _rewardedInterstitialLoadCompleter = null;
          }
          if (!completer.isCompleted) completer.complete(false);
        },
      ),
    );

    return completer.future.timeout(AdNetworkConfig.adLoadTimeout, onTimeout: () {
      if (identical(_rewardedInterstitialLoadCompleter, completer)) {
        _rewardedInterstitialLoadCompleter = null;
      }
      if (!completer.isCompleted) completer.complete(false);
      print('⚠️ AdMob RewardedInterstitial load timeout');
      return false;
    });
  }

  static Future<void> showRewardedInterstitialAndWait({
    required VoidCallback onReward,
  }) async {
    if (_rewardedInterstitialAd == null) {
      final loaded = await loadRewardedInterstitial();
      if (!loaded || _rewardedInterstitialAd == null) {
        print('⚠️ AdMob RewardedInterstitial not ready');
        return;
      }
    }

    final completer = Completer<void>();
    final ad = _rewardedInterstitialAd!;
    _rewardedInterstitialAd = null;

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) =>
          print('▶ AdMob RewardedInterstitial started'),
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        unawaited(loadRewardedInterstitial());
        print('✅ AdMob RewardedInterstitial dismissed');
        if (!completer.isCompleted) completer.complete();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        unawaited(loadRewardedInterstitial(force: true));
        print('❌ AdMob RewardedInterstitial show failed: $error');
        if (!completer.isCompleted) completer.complete();
      },
    );

    try {
      await ad.show(
        onUserEarnedReward: (ad, reward) {
          print(
            '🎁 AdMob RewardedInterstitial earned: ${reward.amount} ${reward.type}',
          );
          onReward();
        },
      );
    } catch (error) {
      ad.dispose();
      unawaited(loadRewardedInterstitial(force: true));
      print('❌ AdMob RewardedInterstitial show threw: $error');
      if (!completer.isCompleted) completer.complete();
    }

    await completer.future.timeout(const Duration(minutes: 2), onTimeout: () {
      print('⚠️ AdMob RewardedInterstitial show timeout');
    });
  }

  // ── Banner ────────────────────────────────────────────────────────────────
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

  // ── Getters ───────────────────────────────────────────────────────────────
  static bool get isInterstitialReady => _interstitialAd != null;
  static bool get isRewardedReady => _rewardedAd != null;
  static bool get isAppOpenReady => _appOpenAd != null;
  static bool get isRewardedInterstitialReady => _rewardedInterstitialAd != null;

  static void dispose() {
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
    _appOpenAd?.dispose();
    _rewardedInterstitialAd?.dispose();
  }
}
