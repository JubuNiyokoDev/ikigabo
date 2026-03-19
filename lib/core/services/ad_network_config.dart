enum AdNetwork { unity, admob }

class AdNetworkConfig {
  const AdNetworkConfig._();

  // Set to true when the AdMob account is fully approved again.
  static const bool isAdMobEnabled = false;
  static const bool isUnityTestMode = true;
  static const bool showBannerDebugState = true;

  static const AdNetwork bannerPrimaryNetwork = AdNetwork.unity;
  static const AdNetwork fullScreenPrimaryNetwork = AdNetwork.unity;

  static const bool useRewardedForCoreActions = false;
  static const bool showDashboardInterstitial = false;
  static const bool showSettingsInterstitial = false;

  static const int transactionInterstitialFrequency = 6;
  static const int bankInterstitialFrequency = 8;
  static const int sourceInterstitialFrequency = 8;
  static const int debtInterstitialFrequency = 8;
  static const int assetInterstitialFrequency = 8;
  static const int reportInterstitialFrequency = 6;
  static const Duration interstitialCooldown = Duration(minutes: 3);

  static bool get canUseAdMob => isAdMobEnabled;
  static bool get shouldGateCoreActions => useRewardedForCoreActions;
}
