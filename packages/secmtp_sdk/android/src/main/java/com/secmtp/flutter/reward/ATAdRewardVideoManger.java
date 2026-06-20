package com.secmtp.flutter.reward;

import androidx.annotation.NonNull;
import android.text.TextUtils;

import com.secmtp.flutter.HandleSecmtpMethod;
import com.secmtp.flutter.utils.Const;
import com.secmtp.flutter.utils.MsgTools;

import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

public class ATAdRewardVideoManger implements HandleSecmtpMethod {

    Map<String, ATRewardVideoHelper> pidHelperMap = new ConcurrentHashMap<>();

    private static class SingletonClassInstance {
        private static final ATAdRewardVideoManger instance = new ATAdRewardVideoManger();
    }

    private ATAdRewardVideoManger() {
    }

    public static ATAdRewardVideoManger getInstance() {
        return SingletonClassInstance.instance;
    }

    @Override
    public boolean handleMethodCall(@NonNull MethodCall methodCall, @NonNull MethodChannel.Result result) {

        String placementID = methodCall.argument(Const.PLACEMENT_ID);
        String placementIDs = methodCall.argument(Const.PLACEMENT_ID_Multi);

        String[] placementIdArr = null;

        boolean isAutoFlag = false;

        if (!TextUtils.isEmpty(placementID) && ATAutoLoadRewardVideoHelper.getInstance().containsPlacementID(placementID)) {
            //全自动加载的操作
            isAutoFlag = true;
            placementIdArr = new String[1];
            placementIdArr[0] = placementID;
        }
        if (TextUtils.isEmpty(placementID) && !TextUtils.isEmpty(placementIDs)) {
            //全自动加载的操作
            isAutoFlag = true;
            placementIdArr = placementIDs.split("\\s*,\\s*");
        }

        if (isAutoFlag) {
            routeAutoLoad(placementIdArr,methodCall,result);
        }else {
            routeNormal(placementID,methodCall,result);
        }

        return true;
    }

    private ATRewardVideoHelper getHelper(String placementId) {

        ATRewardVideoHelper helper;

        if (!pidHelperMap.containsKey(placementId)) {
            helper = new ATRewardVideoHelper();
            pidHelperMap.put(placementId, helper);
        } else {
            helper = pidHelperMap.get(placementId);
        }

        return helper;
    }

    private void routeNormal(String placementID, @NonNull MethodCall methodCall, @NonNull MethodChannel.Result result) {

        if (TextUtils.isEmpty(placementID)) {
            MsgTools.printMsg("ATAdRewardVideoManger routeNormal: The placementID parameter is null or empty.");
            return;
        }

        ATRewardVideoHelper helper = getHelper(placementID);

        switch (methodCall.method) {
            case "loadRewardedVideo":
                if (helper != null) {
                    Map<String, Object> settingMap = methodCall.argument(Const.EXTRA_DIC);

                    helper.loadRewardedVideo(placementID, settingMap);
                }
                result.success("");
                break;
            case "showRewardedVideo":
                if (helper != null) {
                    helper.showRewardedVideo("");
                }
                result.success("");
                break;
            case "showSceneRewardedVideo":
                if (helper != null) {
                    String scenario = methodCall.argument(Const.SCENE_ID);
                    helper.showRewardedVideo(scenario);
                }
                result.success("");
                break;
            case "showRewardedVideoWithShowConfig":
                if (helper != null) {
                    String scenario = methodCall.argument(Const.SCENE_ID);
                    String showCustomExt = methodCall.argument(Const.SHOW_CUSTOM_EXT);
                    helper.showConfigRewardedVideo(scenario,showCustomExt);
                }
                result.success("");
                break;
            case "rewardedVideoReady":
                if (helper != null) {
                    boolean adReady = helper.isAdReady();
                    result.success(adReady);
                } else {
                    result.success(false);
                }
                break;
            case "checkRewardedVideoLoadStatus":
                if (helper != null) {
                    Map<String, Object> map = helper.checkAdStatus();
                    result.success(map);
                } else {
                    result.success(new HashMap<String, Object>(1));
                }
                break;
            case "getRewardedVideoValidAds":
                if (helper != null) {
                    String s = helper.checkValidAdCaches();
                    result.success(s);
                } else {
                    result.success("");
                }
                break;
            case "entryRewardedVideoScenario":
                if (helper != null) {
                    String scenario = methodCall.argument(Const.SCENE_ID);
                    helper.entryScenario(placementID,scenario);
                }
                result.success("");
                break;
        }
    }

    private void routeAutoLoad(String[] placementIDArr,@NonNull MethodCall methodCall, @NonNull MethodChannel.Result result) {

        ATAutoLoadRewardVideoHelper helper = ATAutoLoadRewardVideoHelper.getInstance();

        String placementID = placementIDArr[0];
        String scenario = methodCall.argument(Const.SCENE_ID);

        switch (methodCall.method) {
            case "rewardedVideoReady":
                boolean adReady = helper.isAdReady(placementID);
                result.success(adReady);
                break;
            case "checkRewardedVideoLoadStatus":
                Map<String, Object> map = helper.checkAdStatus(placementID);
                result.success(map);
                break;
            case "getRewardedVideoValidAds":
                String s = helper.checkValidAdCaches(placementID);
                result.success(s);
                break;
            case "entryRewardedVideoScenario":
                helper.entryScenario(placementID,scenario);
                result.success("");
                break;
            case "autoLoadRewardedVideoAD":
                if (helper != null) {
                    helper.autoLoadRewardedVideo(placementIDArr);
                }
                result.success("");
                break;
            case "cancelAutoLoadRewardedVideoAD":
                if (helper != null) {
                    helper.removePlacementId(placementIDArr);
                }
                result.success("");
                break;
            case "showAutoLoadRewardedVideoAD":
                if (helper != null) {
                    helper.showAutoLoadRewardedVideoAD(placementID,scenario);
                }
                result.success("");
                break;
            case "autoLoadRewardedVideoADSetLocalExtra":
                if (helper != null) {
                    Map<String, Object> settingMap = methodCall.argument(Const.EXTRA_DIC);
                    helper.autoLoadRewardedVideoSetLocalExtra(placementID,settingMap);
                }
                result.success("");
                break;
        }
    }
}
