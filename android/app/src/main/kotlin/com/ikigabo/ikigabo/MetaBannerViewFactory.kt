package com.ikigabo.ikigabo

import android.content.Context
import android.view.View
import android.widget.FrameLayout
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

class MetaBannerViewFactory(private val plugin: MetaAdsPlugin) :
    PlatformViewFactory(StandardMessageCodec.INSTANCE) {

    override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
        return MetaBannerPlatformView(context, plugin)
    }
}

private class MetaBannerPlatformView(
    private val context: Context,
    private val plugin: MetaAdsPlugin,
) : PlatformView {

    override fun getView(): View {
        return plugin.getBannerView() ?: FrameLayout(context)
    }

    override fun dispose() {}
}
