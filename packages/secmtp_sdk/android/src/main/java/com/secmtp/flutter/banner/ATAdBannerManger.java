package com.secmtp.flutter.banner;

import androidx.annotation.NonNull;

import com.secmtp.flutter.HandleSecmtpMethod;
import com.secmtp.flutter.utils.Const;

import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

public class ATAdBannerManger implements HandleSecmtpMethod {
    Map<String, ATBannerHelper> pidHelperMap = new ConcurrentHashMap<>();

    private static class SingletonClassInstance {
        private static final ATAdBannerManger instance = new ATAdBannerManger();
    }

    private ATAdBannerManger() {
    }

    public static ATAdBannerManger getInstance() {
        return SingletonClassInstance.instance;
    }

    @Override
    public boolean handleMethodCall(@NonNull MethodCall methodCall, @NonNull MethodChannel.Result result) {

        String placementID = methodCall.argument(Const.PLACEMENT_ID);
        Map<String, Object> setting = methodCall.argument(Const.EXTRA_DIC);

        ATBannerHelper helper = getHelper(placementID);

        switch (methodCall.method) {
            case "loadBannerAd":
                if (helper != null) {
                    helper.loadBanner(placementID, setting);
                }
                result.success("");
                break;
            case "bannerAdReady":
                if (helper != null) {
                    boolean adReady = helper.isAdReady();
                    result.success(adReady);
                } else {
                    result.success(false);
                }
                break;
            case "checkBannerLoadStatus":
                if (helper != null) {
                    Map<String, Object> map = helper.checkAdStatus();
                    result.success(map);
                } else {
                    result.success(new HashMap<String, Object>(1));
                }
                break;
            case "getBannerValidAds":
                if (helper != null) {
                    String s = helper.checkValidAdCaches();
                    result.success(s);
                } else {
                    result.success("");
                }
                break;
            case "showBannerInRectangle":
                if (helper != null) {
                    helper.showBannerWithRect(setting, null);
                }
                result.success("");
                break;
            case "showSceneBannerInRectangle":
                if (helper != null) {
                    String scenario = methodCall.argument(Const.SCENE_ID);

                    helper.showBannerWithRect(setting, scenario);
                }
                result.success("");
                break;
            case "showAdInPosition":
                if (helper != null) {
                    String position = methodCall.argument(Const.POSITION);

                    helper.showBannerWithPosition(position, null, null);
                }
                result.success("");
                break;
            case "showSceneBannerAdInPosition":
                if (helper != null) {
                    String position = methodCall.argument(Const.POSITION);
                    String scenario = methodCall.argument(Const.SCENE_ID);
                    String showCustomExt = methodCall.argument(Const.SHOW_CUSTOM_EXT);
                    helper.showBannerWithPosition(position, scenario, showCustomExt);
                }
                result.success("");
                break;
            case "removeBannerAd":
                if (helper != null) {
                    helper.removeBanner();
                }
                result.success("");
                break;
            case "hideBannerAd":
                if (helper != null) {
                    helper.hideBanner();
                }
                result.success("");
                break;
            case "afreshShowBannerAd":
                if (helper != null) {
                    helper.reshowBanner();
                }
                result.success("");
                break;
            case "entryBannerScenario":
                if (helper != null) {
                    String scenario = methodCall.argument(Const.SCENE_ID);
                    helper.entryScenario(placementID,scenario);
                }
                result.success(true);
                break;
        }
        return true;
    }

    public ATBannerHelper getHelper(String placementId) {

        ATBannerHelper helper;

        if (!pidHelperMap.containsKey(placementId)) {
            helper = new ATBannerHelper();
            pidHelperMap.put(placementId, helper);
        } else {
            helper = pidHelperMap.get(placementId);
        }

        return helper;
    }

}
