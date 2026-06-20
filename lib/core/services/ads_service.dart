import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:secmtp_sdk/at_index.dart';

import 'ad_policy.dart';
import 'topon_ad_config.dart';

class AdsService {
  static bool _isInitialized = false;
  static bool _automaticLoadingEnabled = false;
  static Completer<bool>? _initializeCompleter;
  static DateTime? _lastInitializationFailure;

  static StreamSubscription<ATInterstitialResponse>? _interstitialSubscription;
  static StreamSubscription<ATRewardResponse>? _rewardedSubscription;
  static StreamSubscription<ATBannerResponse>? _bannerSubscription;
  static StreamSubscription<ATNativeResponse>? _nativeSubscription;

  static Completer<bool>? _interstitialLoadCompleter;
  static Completer<void>? _interstitialShowCompleter;
  static Completer<bool>? _rewardedLoadCompleter;
  static Completer<void>? _rewardedShowCompleter;
  static VoidCallback? _pendingReward;
  static bool _rewardGranted = false;

  static final Map<String, Completer<bool>> _bannerLoadCompleters = {};
  static final Map<String, DateTime> _bannerRetryAfter = {};
  static Completer<bool>? _nativeLoadCompleter;

  static Future<bool> initialize() async {
    if (_isInitialized) return true;
    if (_initializeCompleter != null) return _initializeCompleter!.future;
    if (_lastInitializationFailure != null &&
        DateTime.now().difference(_lastInitializationFailure!) <
            AdPolicy.sdkInitializationRetryDelay) {
      return false;
    }

    final completer = Completer<bool>();
    _initializeCompleter = completer;

    try {
      _bindListeners();
      try {
        await ATInitManger.setLogEnabled(logEnabled: kDebugMode);
      } catch (error) {
        debugPrint('TopOn debug logging unavailable: $error');
      }
      await ATInitManger.initSDK(
        appidStr: TopOnAdConfig.appId,
        appidkeyStr: TopOnAdConfig.appKey,
      ).timeout(AdPolicy.sdkInitializationTimeout);
      _isInitialized = true;
      _lastInitializationFailure = null;
      await _enableAutomaticLoading();
      debugPrint('TopOn SDK initialized');
    } catch (error) {
      _lastInitializationFailure = DateTime.now();
      debugPrint('TopOn initialization failed: $error');
    } finally {
      if (!completer.isCompleted) completer.complete(_isInitialized);
      _initializeCompleter = null;
    }

    return _isInitialized;
  }

  static Future<void> warmUp() async {
    if (!await initialize()) return;
    if (!_automaticLoadingEnabled) {
      unawaited(loadInterstitial());
      unawaited(
        Future<void>.delayed(const Duration(seconds: 12), () async {
          await loadRewarded();
        }),
      );
    }
  }

  static Future<void> refreshFullScreenCaches() async {
    if (!await initialize()) return;
    if (_automaticLoadingEnabled) return;
    unawaited(loadInterstitial());
    unawaited(loadRewarded());
  }

  static Future<void> _enableAutomaticLoading() async {
    try {
      await ATInterstitialManager.autoLoadInterstitialAD(
        placementIDs: TopOnAdConfig.interstitialPlacementId,
      );
      await ATRewardedManager.autoLoadRewardedVideo(
        placementIDs: TopOnAdConfig.rewardedPlacementId,
      );
      _automaticLoadingEnabled = true;
      debugPrint('TopOn automatic full-screen loading enabled');
    } catch (error) {
      _automaticLoadingEnabled = false;
      debugPrint('TopOn automatic loading unavailable: $error');
    }
  }

  static void _bindListeners() {
    _interstitialSubscription ??= ATListenerManager.interstitialEventHandler
        .listen(_handleInterstitialEvent);
    _rewardedSubscription ??= ATListenerManager.rewardedVideoEventHandler
        .listen(_handleRewardedEvent);
    _bannerSubscription ??= ATListenerManager.bannerEventHandler.listen(
      _handleBannerEvent,
    );
    _nativeSubscription ??= ATListenerManager.nativeEventHandler.listen(
      _handleNativeEvent,
    );
  }

  static Future<bool> loadInterstitial() async {
    if (!await initialize()) return false;

    try {
      if (await ATInterstitialManager.hasInterstitialAdReady(
        placementID: TopOnAdConfig.interstitialPlacementId,
      )) {
        return true;
      }
    } catch (_) {}

    if (_interstitialLoadCompleter != null) {
      return _interstitialLoadCompleter!.future;
    }

    final completer = Completer<bool>();
    _interstitialLoadCompleter = completer;
    if (!_automaticLoadingEnabled) {
      try {
        await ATInterstitialManager.loadInterstitialAd(
          placementID: TopOnAdConfig.interstitialPlacementId,
          extraMap: const {},
        );
      } catch (error) {
        _completeInterstitialLoad(false);
        debugPrint('TopOn interstitial load failed to start: $error');
      }
    }

    return completer.future.timeout(
      AdPolicy.adLoadTimeout,
      onTimeout: () {
        _completeInterstitialLoad(false);
        debugPrint('TopOn interstitial load timeout');
        return false;
      },
    );
  }

  static Future<bool> showInterstitial() async {
    if (!await initialize()) return false;

    try {
      final ready = await ATInterstitialManager.hasInterstitialAdReady(
        placementID: TopOnAdConfig.interstitialPlacementId,
      );
      if (!ready) {
        if (!_automaticLoadingEnabled) unawaited(loadInterstitial());
        return false;
      }
    } catch (_) {
      return false;
    }

    final completer = Completer<void>();
    _interstitialShowCompleter = completer;
    try {
      if (_automaticLoadingEnabled) {
        await ATInterstitialManager.showAutoLoadInterstitialAD(
          placementID: TopOnAdConfig.interstitialPlacementId,
          sceneID: '',
        );
      } else {
        await ATInterstitialManager.showInterstitialAd(
          placementID: TopOnAdConfig.interstitialPlacementId,
        );
      }
      await completer.future.timeout(
        const Duration(minutes: 2),
        onTimeout: () {
          _completeInterstitialShow();
        },
      );
      if (!_automaticLoadingEnabled) unawaited(loadInterstitial());
      return true;
    } catch (error) {
      _completeInterstitialShow();
      if (!_automaticLoadingEnabled) unawaited(loadInterstitial());
      debugPrint('TopOn interstitial show failed: $error');
      return false;
    }
  }

  static Future<bool> loadRewarded() async {
    if (!await initialize()) return false;

    try {
      if (await ATRewardedManager.rewardedVideoReady(
        placementID: TopOnAdConfig.rewardedPlacementId,
      )) {
        return true;
      }
    } catch (_) {}

    if (_rewardedLoadCompleter != null) {
      return _rewardedLoadCompleter!.future;
    }

    final completer = Completer<bool>();
    _rewardedLoadCompleter = completer;
    if (!_automaticLoadingEnabled) {
      try {
        await ATRewardedManager.loadRewardedVideo(
          placementID: TopOnAdConfig.rewardedPlacementId,
          extraMap: const {},
        );
      } catch (error) {
        _completeRewardedLoad(false);
        debugPrint('TopOn rewarded load failed to start: $error');
      }
    }

    return completer.future.timeout(
      AdPolicy.adLoadTimeout,
      onTimeout: () {
        _completeRewardedLoad(false);
        debugPrint('TopOn rewarded load timeout');
        return false;
      },
    );
  }

  static Future<bool> showRewarded({required VoidCallback onReward}) async {
    if (!await loadRewarded()) return false;

    _pendingReward = onReward;
    _rewardGranted = false;
    final completer = Completer<void>();
    _rewardedShowCompleter = completer;

    try {
      if (_automaticLoadingEnabled) {
        await ATRewardedManager.showAutoLoadRewardedVideoAD(
          placementID: TopOnAdConfig.rewardedPlacementId,
          sceneID: '',
        );
      } else {
        await ATRewardedManager.showRewardedVideo(
          placementID: TopOnAdConfig.rewardedPlacementId,
        );
      }
      await completer.future.timeout(
        const Duration(minutes: 3),
        onTimeout: () {
          _completeRewardedShow();
        },
      );
      final rewarded = _rewardGranted;
      _pendingReward = null;
      if (!_automaticLoadingEnabled) unawaited(loadRewarded());
      return rewarded;
    } catch (error) {
      _pendingReward = null;
      _completeRewardedShow();
      if (!_automaticLoadingEnabled) unawaited(loadRewarded());
      debugPrint('TopOn rewarded show failed: $error');
      return false;
    }
  }

  static Future<bool> loadBanner({
    required String placementId,
    required double width,
    required double height,
  }) async {
    if (!await initialize()) return false;

    final retryAfter = _bannerRetryAfter[placementId];
    if (retryAfter != null && DateTime.now().isBefore(retryAfter)) {
      return false;
    }

    try {
      if (await ATBannerManager.bannerAdReady(placementID: placementId)) {
        _bannerRetryAfter.remove(placementId);
        return true;
      }
    } catch (_) {}

    final pending = _bannerLoadCompleters[placementId];
    if (pending != null) return pending.future;

    final completer = Completer<bool>();
    _bannerLoadCompleters[placementId] = completer;

    try {
      await ATBannerManager.loadBannerAd(
        placementID: placementId,
        extraMap: {
          ATCommon.isNativeShow(): true,
          ATCommon.getAdSizeKey(): ATBannerManager.createLoadBannerAdSize(
            width,
            height,
          ),
          ATBannerManager.getAdaptiveWidthKey(): width,
          ATBannerManager.getAdaptiveOrientationKey():
              ATBannerManager.adaptiveOrientationCurrent(),
        },
      );
    } catch (error) {
      _completeBannerLoad(placementId, false);
      debugPrint('TopOn banner load failed to start: $error');
    }

    return completer.future.timeout(
      AdPolicy.adLoadTimeout,
      onTimeout: () {
        _completeBannerLoad(placementId, false);
        debugPrint('TopOn banner load timeout for $placementId');
        return false;
      },
    );
  }

  static Future<bool> loadNative({
    required double width,
    required double height,
  }) async {
    if (!await initialize()) return false;

    try {
      if (await ATNativeManager.nativeAdReady(
        placementID: TopOnAdConfig.nativePlacementId,
      )) {
        return true;
      }
    } catch (_) {}

    if (_nativeLoadCompleter != null) return _nativeLoadCompleter!.future;

    final completer = Completer<bool>();
    _nativeLoadCompleter = completer;

    try {
      await ATNativeManager.loadNativeAd(
        placementID: TopOnAdConfig.nativePlacementId,
        extraMap: {
          ATCommon.isNativeShow(): false,
          ATCommon.getAdSizeKey(): ATNativeManager.createNativeSubViewAttribute(
            width,
            height,
          ),
          ATNativeManager.isAdaptiveHeight(): false,
        },
      );
    } catch (error) {
      _completeNativeLoad(false);
      debugPrint('TopOn native load failed to start: $error');
    }

    return completer.future.timeout(
      AdPolicy.adLoadTimeout,
      onTimeout: () {
        _completeNativeLoad(false);
        debugPrint('TopOn native load timeout');
        return false;
      },
    );
  }

  static Future<void> removeNative() async {
    try {
      await ATNativeManager.removeNativeAd(
        placementID: TopOnAdConfig.nativePlacementId,
      );
    } catch (_) {}
  }

  static void _handleInterstitialEvent(ATInterstitialResponse event) {
    if (event.placementID != TopOnAdConfig.interstitialPlacementId) return;

    switch (event.interstatus) {
      case InterstitialStatus.interstitialAdDidFinishLoading:
      case InterstitialStatus.interstitialAdDidMultipleLoaded:
        _completeInterstitialLoad(true);
        debugPrint('TopOn interstitial loaded');
      case InterstitialStatus.interstitialDidShowSucceed:
        debugPrint('TopOn interstitial shown');
      case InterstitialStatus.interstitialAdFailToLoadAD:
        _completeInterstitialLoad(false);
        debugPrint('TopOn interstitial load error: ${event.requestMessage}');
      case InterstitialStatus.interstitialAdDidClose:
      case InterstitialStatus.interstitialFailedToShow:
      case InterstitialStatus.interstitialDidFailToPlayVideo:
        _completeInterstitialShow();
      default:
        break;
    }
  }

  static void _handleRewardedEvent(ATRewardResponse event) {
    if (event.placementID != TopOnAdConfig.rewardedPlacementId) return;

    switch (event.rewardStatus) {
      case RewardedStatus.rewardedVideoDidFinishLoading:
      case RewardedStatus.rewardedVideoDidMultipleLoaded:
        _completeRewardedLoad(true);
        debugPrint('TopOn rewarded loaded');
      case RewardedStatus.rewardedVideoDidStartPlaying:
        debugPrint('TopOn rewarded shown');
      case RewardedStatus.rewardedVideoDidFailToLoad:
        _completeRewardedLoad(false);
        debugPrint('TopOn rewarded load error: ${event.requestMessage}');
      case RewardedStatus.rewardedVideoDidRewardSuccess:
      case RewardedStatus.rewardedVideoDidAgainRewardSuccess:
        if (!_rewardGranted) {
          _rewardGranted = true;
          _pendingReward?.call();
        }
      case RewardedStatus.rewardedVideoDidClose:
      case RewardedStatus.rewardedVideoDidFailToPlay:
        _completeRewardedShow();
      default:
        break;
    }
  }

  static void _handleBannerEvent(ATBannerResponse event) {
    switch (event.bannerStatus) {
      case BannerStatus.bannerAdDidFinishLoading:
      case BannerStatus.bannerAdDidMultipleLoaded:
        _completeBannerLoad(event.placementID, true);
        debugPrint('TopOn banner loaded (${event.placementID})');
      case BannerStatus.bannerAdDidShowSucceed:
        debugPrint('TopOn banner shown (${event.placementID})');
      case BannerStatus.bannerAdFailToLoadAD:
        _completeBannerLoad(event.placementID, false);
        debugPrint(
          'TopOn banner load error (${event.placementID}): '
          '${event.requestMessage}',
        );
      default:
        break;
    }
  }

  static void _handleNativeEvent(ATNativeResponse event) {
    if (event.placementID != TopOnAdConfig.nativePlacementId) return;

    switch (event.nativeStatus) {
      case NativeStatus.nativeAdDidFinishLoading:
      case NativeStatus.nativeAdDidMultipleLoaded:
        _completeNativeLoad(true);
        debugPrint('TopOn native loaded');
      case NativeStatus.nativeAdDidShowNativeAd:
        debugPrint('TopOn native shown');
      case NativeStatus.nativeAdFailToLoadAD:
        _completeNativeLoad(false);
        debugPrint('TopOn native load error: ${event.requestMessage}');
      default:
        break;
    }
  }

  static void _completeInterstitialLoad(bool loaded) {
    final completer = _interstitialLoadCompleter;
    _interstitialLoadCompleter = null;
    if (completer != null && !completer.isCompleted) {
      completer.complete(loaded);
    }
  }

  static void _completeInterstitialShow() {
    final completer = _interstitialShowCompleter;
    _interstitialShowCompleter = null;
    if (completer != null && !completer.isCompleted) completer.complete();
  }

  static void _completeRewardedLoad(bool loaded) {
    final completer = _rewardedLoadCompleter;
    _rewardedLoadCompleter = null;
    if (completer != null && !completer.isCompleted) {
      completer.complete(loaded);
    }
  }

  static void _completeRewardedShow() {
    final completer = _rewardedShowCompleter;
    _rewardedShowCompleter = null;
    if (completer != null && !completer.isCompleted) completer.complete();
  }

  static void _completeBannerLoad(String placementId, bool loaded) {
    if (loaded) {
      _bannerRetryAfter.remove(placementId);
    } else {
      _bannerRetryAfter[placementId] = DateTime.now().add(
        AdPolicy.bannerRetryDelay,
      );
    }

    final completer = _bannerLoadCompleters.remove(placementId);
    if (completer != null && !completer.isCompleted) {
      completer.complete(loaded);
    }
  }

  static void _completeNativeLoad(bool loaded) {
    final completer = _nativeLoadCompleter;
    _nativeLoadCompleter = null;
    if (completer != null && !completer.isCompleted) {
      completer.complete(loaded);
    }
  }
}
