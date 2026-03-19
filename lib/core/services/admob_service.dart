import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdMobService {
  // 🔑 IDs ADMOB
  static const String _bannerAdUnitId =
      'ca-app-pub-2300546388710165/5022166817';
  static const String _interstitialAdUnitId =
      'ca-app-pub-2300546388710165/3121943541';
  static const String _rewardedAdUnitId =
      'ca-app-pub-2300546388710165/8111364581';

  static bool _isInitialized = false;
  static InterstitialAd? _interstitialAd;
  static RewardedAd? _rewardedAd;

  // 🔹 INIT ADMOB
  static Future<void> initialize() async {
    if (_isInitialized) return;

    await MobileAds.instance.initialize();
    _isInitialized = true;
    print('✅ AdMob initialized');

    // Preload ads
    _loadInterstitial();
    _loadRewarded();
  }

  // 🔹 LOAD INTERSTITIAL
  static Future<void> _loadInterstitial() async {
    if (!_isInitialized) await initialize();

    await InterstitialAd.load(
      adUnitId: _interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          print('✅ AdMob Interstitial loaded');
        },
        onAdFailedToLoad: (error) {
          print('❌ AdMob Interstitial failed: $error');
          _interstitialAd = null;
        },
      ),
    );
  }

  // 🔹 SHOW INTERSTITIAL
  static Future<void> showInterstitial() async {
    if (_interstitialAd == null) {
      print('⚠️ AdMob Interstitial not ready');
      return;
    }

    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _interstitialAd = null;
        _loadInterstitial(); // Reload for next time
        print('✅ AdMob Interstitial dismissed');
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _interstitialAd = null;
        _loadInterstitial();
        print('❌ AdMob Interstitial show failed: $error');
      },
    );

    await _interstitialAd!.show();
  }

  // 🔹 LOAD REWARDED
  static Future<void> _loadRewarded() async {
    if (!_isInitialized) await initialize();

    await RewardedAd.load(
      adUnitId: _rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          print('✅ AdMob Rewarded loaded');
        },
        onAdFailedToLoad: (error) {
          print('❌ AdMob Rewarded failed: $error');
          _rewardedAd = null;
        },
      ),
    );
  }

  // 🔹 SHOW REWARDED
  static Future<void> showRewarded({required Function() onReward}) async {
    if (_rewardedAd == null) {
      print('⚠️ AdMob Rewarded not ready');
      return;
    }

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedAd = null;
        _loadRewarded(); // Reload for next time
        print('✅ AdMob Rewarded dismissed');
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _rewardedAd = null;
        _loadRewarded();
        print('❌ AdMob Rewarded show failed: $error');
      },
    );

    await _rewardedAd!.show(
      onUserEarnedReward: (ad, reward) {
        print('🎁 AdMob Reward earned: ${reward.amount} ${reward.type}');
        onReward();
      },
    );
  }

  // 🔹 CREATE BANNER
  static BannerAd createBanner() {
    return BannerAd(
      adUnitId: _bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) => print('✅ AdMob Banner loaded'),
        onAdFailedToLoad: (ad, error) {
          print('❌ AdMob Banner failed: $error');
          ad.dispose();
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
