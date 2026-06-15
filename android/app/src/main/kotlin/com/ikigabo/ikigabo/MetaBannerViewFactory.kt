package com.ikigabo.ikigabo

import android.content.Context
import android.view.View
import android.widget.FrameLayout
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

class MetaBannerViewFactory(private val plugin: MetaAdsPlugin) :
    PlatformViewFactory(StandardMessageCodec.INSTANCE) {

    override fun create(context: Context, viewId: Int, args: Any?): PlatformView =
        MetaNativeAdView(context) { plugin.getBannerView() }
}

class MetaRectangleViewFactory(private val plugin: MetaAdsPlugin) :
    PlatformViewFactory(StandardMessageCodec.INSTANCE) {

    override fun create(context: Context, viewId: Int, args: Any?): PlatformView =
        MetaNativeAdView(context) { plugin.getRectangleView() }
}

private class MetaNativeAdView(
    private val context: Context,
    private val viewProvider: () -> View?,
) : PlatformView {
    override fun getView(): View = viewProvider() ?: FrameLayout(context)
    override fun dispose() {}
}
