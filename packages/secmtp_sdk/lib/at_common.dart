final ATCommonTool = ATCommon();

class ATCommon {
  static String getAdSizeKey() {
    return 'size';
  }

  /// iOS 支持：原生广告加载时传入 mediaView 的 frame。
  ///
  /// Flutter ：
  /// {
  ///   ATCommon.getMediaViewFrameKey(): {
  ///     "x": 0,
  ///     "y": 100,
  ///     "width": 320,
  ///     "height": 180,
  ///   }
  /// }
  static String getMediaViewFrameKey() {
    return 'mediaViewFrame';
  }

  static String getShowCustomExtKey() {
    return 'showCustomExt';
  }

  static String getAdATBannerAdShowingPositionTop() {
    return 'kATBannerAdShowingPositionTop';
  }

  static String getAdATBannerAdShowingPositionBottom() {
    return 'kATBannerAdShowingPositionBottom';
  }

  /// `loadNativeAd` 的分流标记（写在 `extraMap` 里）。
  ///
  /// - `true`（默认）: 走 NativeShow 链路，通常配合 `showNativeAd` 由 iOS 原生直接 addSubview 展示。
  /// - `false`: 走 PlatformView 链路，通常配合 `PlatformNativeWidget` 在 Flutter Widget 树中承载展示。
  ///
  /// 建议：
  /// - Flutter 页面内嵌展示优先用 `false`（PlatformView）。
  /// - 全屏/悬浮等原生直接展示场景可用 `true`。
  static String isNativeShow() {
    return 'isNativeShowType';
  }

  static String getNativeRenderTypeKey() {
    return 'nativeRenderType';
  }

  static String getNativeRenderTypeExpress() {
    return 'express';
  }

  static String getNativeRenderTypeSelfRender() {
    return 'selfRender';
  }

  static String getBiddingAttemptKey() {
    return 'bidding_attempt';
  }

  static String getLoadingKey() {
    return 'loading';
  }
}
