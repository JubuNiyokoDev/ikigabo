import 'package:flutter/foundation.dart';

enum AdNetwork { unity, admob }

class AdNetworkConfig {
  const AdNetworkConfig._();

  // AdMob et Unity sont tous les deux actifs simultanément
  static const bool isAdMobEnabled = true;
  static const bool useTestAds = false;
  static const bool isUnityTestMode = useTestAds;
  static const bool showBannerDebugState = kDebugMode;
  static const List<String> adMobTestDeviceIds = <String>[
    'A13309D31987749D96D20C4C55979E7F',
  ];

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
  static const Duration adLoadTimeout = Duration(seconds: 30);
  static const Duration bannerRetryDelay = Duration(seconds: 20);
  static const Duration bannerRotationInterval = Duration(seconds: 30);

  static bool get canUseAdMob => isAdMobEnabled;
  static bool get shouldGateCoreActions => useRewardedForCoreActions;
}
