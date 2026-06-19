package com.secmtp.flutter.reward;

import android.app.Activity;
import android.content.Context;
import android.text.TextUtils;

//import com.anythink.china.api.ATAppDownloadListener;
//import com.anythink.core.api.ATSDK;
import com.secmtp.flutter.ATFlutterEventManager;
import com.secmtp.flutter.utils.Const;
import com.secmtp.flutter.utils.FlutterPluginUtil;
import com.secmtp.flutter.utils.MsgTools;
import com.secmtp.flutter.commonlistener.AdRevenueListenerImpl;

import com.secmtp.flutter.utils.Utils;
import com.secmtp.sdk.core.api.ATAdInfo;
import com.secmtp.sdk.core.api.ATAdMultipleLoadedListener;
import com.secmtp.sdk.core.api.ATAdSourceStatusListener;
import com.secmtp.sdk.core.api.ATAdStatusInfo;
import com.secmtp.sdk.core.api.ATNetworkConfirmInfo;
import com.secmtp.sdk.core.api.ATRequestingInfo;
import com.secmtp.sdk.core.api.ATShowConfig;
import com.secmtp.sdk.core.api.AdError;
import com.secmtp.sdk.rewardvideo.api.ATRewardVideoAd;
import com.secmtp.sdk.rewardvideo.api.ATRewardVideoExListener;

import org.json.JSONArray;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class ATRewardVideoHelper {

    ATRewardVideoAd mRewardVideoAd;
    String mPlacementId;

    private void initRewardVideo(final String placementId) {
        Activity activity = FlutterPluginUtil.getActivity();
        if (!FlutterPluginUtil.isActivityUsable(activity)) {
            MsgTools.printMsg("initRewardVideo: activity invalid, placementId=" + placementId);
            return;
        }
        mPlacementId = placementId;
        mRewardVideoAd = new ATRewardVideoAd(activity, placementId);
        mRewardVideoAd.setAdListener(new ATRewardVideoExListener() {
            @Override
            public void onRewardFailed(ATAdInfo atAdInfo) {
                //todo
            }

            @Override
            public void onDeeplinkCallback(ATAdInfo atAdInfo, boolean isSuccess) {
                MsgTools.printMsg("video onDeeplinkCallback: " + mPlacementId);

                Map<String, Object> extraMap = new HashMap<>();
                extraMap.put(Const.CallbackKey.isDeeplinkSuccess, isSuccess);

                ATFlutterEventManager.getInstance().sendCallbackMsgToFlutter(
                        Const.CallbackMethodCall.rewardedVideoCall, Const.RewardVideoCallback.DeeplinkCallbackKey,
                        mPlacementId, atAdInfo.toString(), null, extraMap);
            }

            @Override
            public void onDownloadConfirm(Context context, ATAdInfo atAdInfo, ATNetworkConfirmInfo atNetworkConfirmInfo) {
                MsgTools.printMsg("video onDownloadConfirm: " + mPlacementId);
            }

            @Override
            public void onRewardedVideoAdAgainPlayStart(ATAdInfo atAdInfo) {
                MsgTools.printMsg("onRewardedVideoAdAgainPlayStart: " + mPlacementId);

                ATFlutterEventManager.getInstance().sendCallbackMsgToFlutter(
                        Const.CallbackMethodCall.rewardedVideoCall, Const.RewardVideoCallback.AgainPlayStartCallbackKey,
                        mPlacementId, atAdInfo.toString(), null);
            }

            @Override
            public void onRewardedVideoAdAgainPlayEnd(ATAdInfo atAdInfo) {
                MsgTools.printMsg("onRewardedVideoAdAgainPlayEnd: " + mPlacementId);

                ATFlutterEventManager.getInstance().sendCallbackMsgToFlutter(
                        Const.CallbackMethodCall.rewardedVideoCall, Const.RewardVideoCallback.AgainPlayEndCallbackKey,
                        mPlacementId, atAdInfo.toString(), null);
            }

            @Override
            public void onRewardedVideoAdAgainPlayFailed(AdError adError, ATAdInfo atAdInfo) {
                MsgTools.printMsg("onRewardedVideoAdAgainPlayFailed: " + mPlacementId);

                ATFlutterEventManager.getInstance().sendCallbackMsgToFlutter(
                        Const.CallbackMethodCall.rewardedVideoCall, Const.RewardVideoCallback.AgainPlayFailCallbackKey,
                        mPlacementId, atAdInfo.toString(), null);
            }

            @Override
            public void onRewardedVideoAdAgainPlayClicked(ATAdInfo atAdInfo) {
                MsgTools.printMsg("onRewardedVideoAdAgainPlayClicked: " + mPlacementId);

                ATFlutterEventManager.getInstance().sendCallbackMsgToFlutter(
                        Const.CallbackMethodCall.rewardedVideoCall, Const.RewardVideoCallback.AgainClickCallbackKey,
                        mPlacementId, atAdInfo.toString(), null);
            }

            @Override
            public void onAgainReward(ATAdInfo atAdInfo) {
                MsgTools.printMsg("onAgainReward: " + mPlacementId);

                ATFlutterEventManager.getInstance().sendCallbackMsgToFlutter(
                        Const.CallbackMethodCall.rewardedVideoCall, Const.RewardVideoCallback.AgainRewardCallbackKey,
                        mPlacementId, atAdInfo.toString(), null);
            }

            @Override
            public void onAgainRewardFailed(ATAdInfo atAdInfo) {
                //todo
            }


            @Override
            public void onRewardedVideoAdLoaded() {
                MsgTools.printMsg("onRewardedVideoAdLoaded: " + mPlacementId);

                ATFlutterEventManager.getInstance().sendCallbackMsgToFlutter(
                        Const.CallbackMethodCall.rewardedVideoCall, Const.RewardVideoCallback.LoadedCallbackKey,
                        mPlacementId, null, null);
            }

            @Override
            public void onRewardedVideoAdFailed(AdError adError) {
                MsgTools.printMsg("onRewardedVideoAdFailed: " + mPlacementId + ", " + adError.getFullErrorInfo());

                ATFlutterEventManager.getInstance().sendCallbackMsgToFlutter(
                        Const.CallbackMethodCall.rewardedVideoCall, Const.RewardVideoCallback.LoadFailCallbackKey,
                        mPlacementId, null, adError.getFullErrorInfo());
            }

            @Override
            public void onRewardedVideoAdPlayStart(ATAdInfo atAdInfo) {
                MsgTools.printMsg("onRewardedVideoAdPlayStart: " + mPlacementId);

                ATFlutterEventManager.getInstance().sendCallbackMsgToFlutter(
                        Const.CallbackMethodCall.rewardedVideoCall, Const.RewardVideoCallback.PlayStartCallbackKey,
                        mPlacementId, atAdInfo.toString(), null);
            }

            @Override
            public void onRewardedVideoAdPlayEnd(ATAdInfo atAdInfo) {
                MsgTools.printMsg("onRewardedVideoAdPlayEnd: " + mPlacementId);

                ATFlutterEventManager.getInstance().sendCallbackMsgToFlutter(
                        Const.CallbackMethodCall.rewardedVideoCall, Const.RewardVideoCallback.PlayEndCallbackKey,
                        mPlacementId, atAdInfo.toString(), null);
            }

            @Override
            public void onRewardedVideoAdPlayFailed(AdError adError, ATAdInfo atAdInfo) {
                MsgTools.printMsg("onRewardedVideoAdPlayFailed: " + mPlacementId + ", " + adError.getFullErrorInfo());

                ATFlutterEventManager.getInstance().sendCallbackMsgToFlutter(
                        Const.CallbackMethodCall.rewardedVideoCall, Const.RewardVideoCallback.PlayFailCallbackKey,
                        mPlacementId, atAdInfo.toString(), adError.getFullErrorInfo());
            }

            @Override
            public void onRewardedVideoAdClosed(ATAdInfo atAdInfo) {
                MsgTools.printMsg("onRewardedVideoAdClosed: " + mPlacementId);

                ATFlutterEventManager.getInstance().sendCallbackMsgToFlutter(
                        Const.CallbackMethodCall.rewardedVideoCall, Const.RewardVideoCallback.CloseCallbackKey,
                        mPlacementId, atAdInfo.toString(), null);
            }

            @Override
            public void onRewardedVideoAdPlayClicked(ATAdInfo atAdInfo) {
                MsgTools.printMsg("onRewardedVideoAdPlayClicked: " + mPlacementId);

                ATFlutterEventManager.getInstance().sendCallbackMsgToFlutter(
                        Const.CallbackMethodCall.rewardedVideoCall, Const.RewardVideoCallback.ClickCallbackKey,
                        mPlacementId, atAdInfo.toString(), null);
            }

            @Override
            public void onReward(ATAdInfo atAdInfo) {
                MsgTools.printMsg("onReward: " + mPlacementId);

                ATFlutterEventManager.getInstance().sendCallbackMsgToFlutter(
                        Const.CallbackMethodCall.rewardedVideoCall, Const.RewardVideoCallback.RewardCallbackKey,
                        mPlacementId, atAdInfo.toString(), null);
            }
        });

        mRewardVideoAd.setAdSourceStatusListener(new ATAdSourceStatusListener() {
            @Override
            public void onAdSourceBiddingAttempt(ATAdInfo adInfo) {
                MsgTools.printMsg("onAdSourceBiddingAttempt: " + mPlacementId + ", " + (adInfo != null ? adInfo.getAdsourceId() : ""));

                ATFlutterEventManager.getInstance().sendAdSourceCallbackMsgToFlutter(
                        Const.CallbackMethodCall.rewardedVideoCall, Const.RewardVideoCallback.AdSourceBiddingAttemptCallbackKey,
                        mPlacementId, adInfo, null);
            }

            @Override
            public void onAdSourceBiddingFilled(ATAdInfo adInfo) {
                MsgTools.printMsg("onAdSourceBiddingFilled: " + mPlacementId + ", " + (adInfo != null ? adInfo.getAdsourceId() : ""));

                ATFlutterEventManager.getInstance().sendAdSourceCallbackMsgToFlutter(
                        Const.CallbackMethodCall.rewardedVideoCall, Const.RewardVideoCallback.AdSourceBiddingFilledCallbackKey,
                        mPlacementId, adInfo, null);
            }

            @Override
            public void onAdSourceBiddingFail(ATAdInfo adInfo, AdError adError) {
                MsgTools.printMsg("onAdSourceBiddingFail: " + mPlacementId + ", " + (adInfo != null ? adInfo.getAdsourceId() : ""));

                ATFlutterEventManager.getInstance().sendAdSourceCallbackMsgToFlutter(
                        Const.CallbackMethodCall.rewardedVideoCall, Const.RewardVideoCallback.AdSourceBiddingFailCallbackKey,
                        mPlacementId, adInfo, adError);
            }

            @Override
            public void onAdSourceAttempt(ATAdInfo adInfo) {
                MsgTools.printMsg("onAdSourceAttempt: " + mPlacementId + ", " + (adInfo != null ? adInfo.getAdsourceId() : ""));

                ATFlutterEventManager.getInstance().sendAdSourceCallbackMsgToFlutter(
                        Const.CallbackMethodCall.rewardedVideoCall, Const.RewardVideoCallback.AdSourceAttemptCallbackKey,
                        mPlacementId, adInfo, null);
            }

            @Override
            public void onAdSourceLoadFilled(ATAdInfo adInfo) {
                MsgTools.printMsg("onAdSourceLoadFilled: " + mPlacementId + ", " + (adInfo != null ? adInfo.getAdsourceId() : ""));

                ATFlutterEventManager.getInstance().sendAdSourceCallbackMsgToFlutter(
                        Const.CallbackMethodCall.rewardedVideoCall, Const.RewardVideoCallback.AdSourceLoadFilledCallbackKey,
                        mPlacementId, adInfo, null);
            }

            @Override
            public void onAdSourceLoadFail(ATAdInfo adInfo, AdError adError) {
                MsgTools.printMsg("onAdSourceLoadFail: " + mPlacementId + ", " + (adInfo != null ? adInfo.getAdsourceId() : ""));

                ATFlutterEventManager.getInstance().sendAdSourceCallbackMsgToFlutter(
                        Const.CallbackMethodCall.rewardedVideoCall, Const.RewardVideoCallback.AdSourceLoadFailCallbackKey,
                        mPlacementId, adInfo, adError);
            }
        });

        mRewardVideoAd.setAdMultipleLoadedListener(new ATAdMultipleLoadedListener() {
            @Override
            public void onAdMultipleLoaded(ATRequestingInfo atRequestingInfo) {
                MsgTools.printMsg("onAdMultipleLoaded: " + mPlacementId);

                ATFlutterEventManager.getInstance().sendCallbackToFlutter(
                        Const.CallbackMethodCall.rewardedVideoCall, Const.RewardVideoCallback.MultipleLoadedCallbackKey,
                        mPlacementId, Utils.getRequestingInfo(atRequestingInfo), null);
            }
        });

        //download
//        try {
//            if (ATSDK.isCnSDK()) {
//                mRewardVideoAd.setAdDownloadListener(new ATAppDownloadListener() {
//                    @Override
//                    public void onDownloadStart(ATAdInfo atAdInfo, long totalBytes, long currBytes, String fileName, String appName) {
//                        MsgTools.printMsg("video onDownloadStart: " + mPlacementId + ", " + totalBytes + ", " + currBytes + ", " + fileName + ", " + appName);
//
//                        ATFlutterEventManager.getInstance().sendDownloadMsgToFlutter(Const.CallbackMethodCall.DownloadCall, Const.DownloadCallCallback.DownloadStartKey,
//                                mPlacementId, atAdInfo.toString(), totalBytes, currBytes, fileName, appName);
//                    }
//
//                    @Override
//                    public void onDownloadUpdate(ATAdInfo atAdInfo, long totalBytes, long currBytes, String fileName, String appName) {
//                        MsgTools.printMsg("video onDownloadUpdate: " + mPlacementId);
//
//                        ATFlutterEventManager.getInstance().sendDownloadMsgToFlutter(Const.CallbackMethodCall.DownloadCall, Const.DownloadCallCallback.DownloadUpdateKey,
//                                mPlacementId, atAdInfo.toString(), totalBytes, currBytes, fileName, appName);
//                    }
//
//                    @Override
//                    public void onDownloadPause(ATAdInfo atAdInfo, long totalBytes, long currBytes, String fileName, String appName) {
//                        MsgTools.printMsg("video onDownloadPause: " + mPlacementId);
//
//                        ATFlutterEventManager.getInstance().sendDownloadMsgToFlutter(Const.CallbackMethodCall.DownloadCall, Const.DownloadCallCallback.DownloadPauseKey,
//                                mPlacementId, atAdInfo.toString(), totalBytes, currBytes, fileName, appName);
//                    }
//
//                    @Override
//                    public void onDownloadFinish(ATAdInfo atAdInfo, long totalBytes, String fileName, String appName) {
//                        MsgTools.printMsg("video onDownloadFinish: " + mPlacementId + ", " + totalBytes  + ", " + fileName + ", " + appName);
//
//                        ATFlutterEventManager.getInstance().sendDownloadMsgToFlutter(Const.CallbackMethodCall.DownloadCall, Const.DownloadCallCallback.DownloadFinishedKey,
//                                mPlacementId, atAdInfo.toString(), totalBytes, -1, fileName, appName);
//                    }
//
//                    @Override
//                    public void onDownloadFail(ATAdInfo atAdInfo, long totalBytes, long currBytes, String fileName, String appName) {
//                        MsgTools.printMsg("video onDownloadFail: " + mPlacementId + ", " + totalBytes + ", " + currBytes + ", " + fileName + ", " + appName);
//
//                        ATFlutterEventManager.getInstance().sendDownloadMsgToFlutter(Const.CallbackMethodCall.DownloadCall, Const.DownloadCallCallback.DownloadFailedKey,
//                                mPlacementId, atAdInfo.toString(), totalBytes, currBytes, fileName, appName);
//                    }
//
//                    @Override
//                    public void onInstalled(ATAdInfo atAdInfo, String fileName, String appName) {
//                        MsgTools.printMsg("video onInstalled: " + mPlacementId + ", " + fileName + ", " + appName);
//
//                        ATFlutterEventManager.getInstance().sendDownloadMsgToFlutter(Const.CallbackMethodCall.DownloadCall, Const.DownloadCallCallback.DownloadInstalledKey,
//                                mPlacementId, atAdInfo.toString(), -1, -1, fileName, appName);
//                    }
//                });
//            }
//        } catch (Throwable e) {
//        }

    }

    public void loadRewardedVideo(final String placementId, final Map<String, Object> settings) {
        MsgTools.printMsg("loadRewardedVideo: " + placementId + ", settings: " + settings);

        if (mRewardVideoAd == null) {
            initRewardVideo(placementId);
        }
        if (mRewardVideoAd == null) {
            MsgTools.printMsg("loadRewardedVideo: mRewardVideoAd null after init, placementId=" + placementId);
            return;
        }

        String userId = "";
        String userData = "";
        try {
            if (settings.containsKey(Const.RewardedVideo.USER_ID)) {
                userId = settings.get(Const.RewardedVideo.USER_ID).toString();
            }
        } catch (Exception e) {
            e.printStackTrace();
        }

        try {
            if (settings.containsKey(Const.RewardedVideo.USER_DATA)) {
                userData = settings.get(Const.RewardedVideo.USER_DATA).toString();
            }
        } catch (Exception e) {
            e.printStackTrace();
        }

        MsgTools.printMsg("loadRewardedVideo: " + placementId + ", userId: " + userId + ", userData: " + userData);

        settings.put("user_id", userId);
        settings.put("user_custom_data", userData);


        mRewardVideoAd.setLocalExtra(settings);
        mRewardVideoAd.load();
    }

    public void showRewardedVideo(final String scenario) {
        MsgTools.printMsg("showRewardedVideo: " + mPlacementId + ", scenario: " + scenario);

        if (mRewardVideoAd != null) {
            Activity activity = FlutterPluginUtil.getActivity();
            if (!FlutterPluginUtil.isActivityUsable(activity)) {
                MsgTools.printMsg("showRewardedVideo: activity invalid, skip show");
                return;
            }
            if (!TextUtils.isEmpty(scenario)) {
                mRewardVideoAd.show(activity, scenario);
            } else {
                mRewardVideoAd.show(activity);
            }
        }
    }

    public void showConfigRewardedVideo(final String scenario, final String showCustomExt) {
        MsgTools.printMsg("showConfigRewardedVideo: " + mPlacementId + ", scenario: " + scenario + ", customShowExt: " + showCustomExt);

        if (mRewardVideoAd != null) {
            Activity activity = FlutterPluginUtil.getActivity();
            if (!FlutterPluginUtil.isActivityUsable(activity)) {
                MsgTools.printMsg("showConfigRewardedVideo: activity invalid, skip show");
                return;
            }
            ATShowConfig.Builder builder = new ATShowConfig.Builder();

            if (!TextUtils.isEmpty(scenario)) {
                builder.scenarioId(scenario);
            }
            if (!TextUtils.isEmpty(showCustomExt)) {
                builder.showCustomExt(showCustomExt);
            }
            mRewardVideoAd.show(activity, builder.build());
        }
    }

    public boolean isAdReady() {
        MsgTools.printMsg("video isAdReady: " + mPlacementId);

        boolean isReady = false;
        if (mRewardVideoAd != null) {
            isReady = mRewardVideoAd.isAdReady();
        }

        MsgTools.printMsg("video isAdReady: " + mPlacementId + ", " + isReady);
        return isReady;
    }

    public Map<String, Object> checkAdStatus() {
        MsgTools.printMsg("video checkAdStatus: " + mPlacementId);

        Map<String, Object> map = new HashMap<>(5);

        if (mRewardVideoAd != null) {
            ATAdStatusInfo atAdStatusInfo = mRewardVideoAd.checkAdStatus();
            boolean loading = atAdStatusInfo.isLoading();
            boolean ready = atAdStatusInfo.isReady();
            ATAdInfo atTopAdInfo = atAdStatusInfo.getATTopAdInfo();

            map.put("isLoading", loading);
            map.put("isReady", ready);

            if (atTopAdInfo != null) {
                map.put("adInfo", atTopAdInfo.toString());
            }

            return map;
        }

        map.put("isLoading", false);
        map.put("isReady", false);

        return map;
    }

    public String checkValidAdCaches() {
        MsgTools.printMsg("video checkValidAdCaches: " + mPlacementId);

        if (mRewardVideoAd != null) {
            List<ATAdInfo> vaildAds = mRewardVideoAd.checkValidAdCaches();
            if (vaildAds == null) {
                return "";
            }

            JSONArray jsonArray = new JSONArray();

            int size = vaildAds.size();
            for (int i = 0; i < size; i++) {
                try {
                    jsonArray.put(new JSONObject(vaildAds.get(i).toString()));
                } catch (Throwable e) {
                    e.printStackTrace();
                }
            }
            return jsonArray.toString();
        }
        return "";
    }

    public void entryScenario(final String placementId,final String sceneID) {
        MsgTools.printMsg("entryRewardVideoScenario: " + mPlacementId + "sceneID: " + sceneID);
        ATRewardVideoAd.entryAdScenario(placementId, sceneID);
    }
}
