import 'package:flutter/foundation.dart';

enum AdNetwork { unity, meta, admob }

class AdNetworkConfig {
  const AdNetworkConfig._();

  static const bool isAdMobEnabled = true;
  static const bool isMetaEnabled = true;
  static const String metaTestDeviceId = '';
  static const bool useTestAds = bool.fromEnvironment(
    'IKIGABO_USE_TEST_ADS',
    defaultValue: !kReleaseMode,
  );
  static const bool isUnityTestMode = useTestAds;
  static const bool showBannerDebugState = kDebugMode;
  static const List<String> adMobTestDeviceIds = <String>[
    'A13309D31987749D96D20C4C55979E7F',
  ];

  static const AdNetwork bannerPrimaryNetwork = AdNetwork.meta;
  static const AdNetwork fullScreenPrimaryNetwork = AdNetwork.meta;

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
  static const Duration bannerRetryDelay = Duration(seconds: 20);
  static const Duration bannerRotationInterval = Duration(seconds: 30);

  static bool get canUseAdMob => isAdMobEnabled;
  static bool get canUseMeta => isMetaEnabled;
  static bool get shouldGateCoreActions => useRewardedForCoreActions;
}
