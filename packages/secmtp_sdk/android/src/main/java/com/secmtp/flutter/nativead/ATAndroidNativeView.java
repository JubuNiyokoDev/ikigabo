package com.secmtp.flutter.nativead;

import android.content.Context;
import android.text.TextUtils;
import android.view.View;

import com.secmtp.flutter.utils.Const;
import com.secmtp.flutter.utils.MsgTools;
import com.secmtp.flutter.utils.PlatformViewImeHelper;
import com.secmtp.sdk.nativead.api.ATNativeAdView;

import java.util.Map;

import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.platform.PlatformView;


public class ATAndroidNativeView implements PlatformView {

    ATNativeAdView anyThinkNativeAdView;

    public ATAndroidNativeView(Context context, BinaryMessenger messenger, int viewID, Map<String, Object> args) {
        try {
            String placementID = (String) args.get(Const.PlatformViewKeys.PlacementID);
            String scenario = (String) args.get(Const.PlatformViewKeys.SceneID);
            boolean isAdaptiveHeight = (Boolean) args.get(Const.PlatformViewKeys.isAdaptiveHeight);
            Map<String, Object> settings = (Map<String, Object>) args.get(Const.PlatformViewKeys.ExtraMap);

            MsgTools.printMsg("ATAndroidNativeView: " + placementID + ", scenario: " + scenario + ", settings: " + settings + ", isAdaptiveHeight: " + isAdaptiveHeight);

            if (TextUtils.isEmpty(placementID)) {
                MsgTools.printMsg("ATAndroidNativeView: placementId = null");
                return;
            }
            String showCustomExt = (String)settings.get(Const.SHOW_CUSTOM_EXT);

            ATNativeHelper helper = ATAdNativeManger.getInstance().getHelper(placementID);
            anyThinkNativeAdView = helper.renderNativeView(settings, scenario, isAdaptiveHeight, true,showCustomExt);
        } catch (Throwable e) {
            e.printStackTrace();
        }
    }
    @Override
    public View getView() {
        return anyThinkNativeAdView;
    }

    @Override
    public void dispose() {
        PlatformViewImeHelper.clearFocusAndHideIme(anyThinkNativeAdView);
    }
}
