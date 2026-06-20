class AdPolicy {
  const AdPolicy._();

  static const bool useRewardedForCoreActions = false;
  static const bool showDashboardInterstitial = true;
  static const bool showSettingsInterstitial = true;

  // Fréquences équilibrées : visible mais pas agressif
  static const int transactionInterstitialFrequency = 2;
  static const int bankInterstitialFrequency = 4;
  static const int sourceInterstitialFrequency = 4;
  static const int debtInterstitialFrequency = 4;
  static const int assetInterstitialFrequency = 4;
  static const int reportInterstitialFrequency = 3;

  // Cooldown 3 min entre 2 pubs plein écran
  static const Duration interstitialCooldown = Duration(minutes: 3);
  static const Duration adLoadTimeout = Duration(seconds: 30);
  static const Duration sdkInitializationTimeout = Duration(seconds: 15);
  static const Duration sdkInitializationRetryDelay = Duration(seconds: 30);
  static const Duration bannerRetryDelay = Duration(minutes: 2);
  static const Duration foregroundCacheRefreshDelay = Duration(seconds: 2);

  static bool get shouldGateCoreActions => useRewardedForCoreActions;
}
