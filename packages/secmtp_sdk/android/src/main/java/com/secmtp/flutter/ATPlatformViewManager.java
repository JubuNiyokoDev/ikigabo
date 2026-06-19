package com.secmtp.flutter;

import com.secmtp.flutter.banner.ATBannerViewFactory;
import com.secmtp.flutter.nativead.ATNativeViewFactory;
import com.secmtp.flutter.utils.Const;

import io.flutter.embedding.engine.plugins.FlutterPlugin;

public class ATPlatformViewManager {

    private static ATPlatformViewManager sInstance;

    private ATPlatformViewManager() {
    }

    public synchronized static ATPlatformViewManager getInstance() {
        if (sInstance == null) {
            sInstance = new ATPlatformViewManager();
        }
        return sInstance;
    }

    public void init(FlutterPlugin.FlutterPluginBinding flutterPluginBinding) {
        flutterPluginBinding.getPlatformViewRegistry().registerViewFactory(Const.PlatformViewName.Banner, new ATBannerViewFactory(flutterPluginBinding.getBinaryMessenger()));
        flutterPluginBinding.getPlatformViewRegistry().registerViewFactory(Const.PlatformViewName.Native, new ATNativeViewFactory(flutterPluginBinding.getBinaryMessenger()));
    }

}
