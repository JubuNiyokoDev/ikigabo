package com.secmtp.flutter.interstitial;

import android.app.Activity;
import android.content.Context;
import android.text.TextUtils;

//import com.anythink.china.api.ATAppDownloadListener;
//import com.anythink.core.api.ATSDK;

import com.secmtp.flutter.ATFlutterEventManager;
import com.secmtp.flutter.utils.Const;
import com.secmtp.flutter.utils.FlutterPluginUtil;
import com.secmtp.flutter.utils.MsgTools;
import com.secmtp.flutter.utils.Utils;
import com.secmtp.sdk.core.api.ATAdInfo;
import com.secmtp.sdk.core.api.ATAdMultipleLoadedListener;
import com.secmtp.sdk.core.api.ATAdSourceStatusListener;
import com.secmtp.sdk.core.api.ATAdStatusInfo;
import com.secmtp.sdk.core.api.ATNetworkConfirmInfo;
import com.secmtp.sdk.core.api.ATRequestingInfo;
import com.secmtp.sdk.core.api.ATShowConfig;
import com.secmtp.sdk.core.api.AdError;
import com.secmtp.sdk.interstitial.api.ATInterstitial;
import com.secmtp.sdk.interstitial.api.ATInterstitialExListener;

import org.json.JSONArray;
import org.json.JSONObject;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class ATInterstitialHelper {

    ATInterstitial mInterstitialAd;
    String mPlacementId;

    private void initInterstitial(final String placementId) {
        Activity activity = FlutterPluginUtil.getActivity();
        if (!FlutterPluginUtil.isActivityUsable(activity)) {
            MsgTools.printMsg("initInterstitial: activity invalid, placementId=" + placementId);
            return;
        }
        mPlacementId = placementId;
        mInterstitialAd = new ATInterstitial(activity, placementId);
        mInterstitialAd.setAdListener(new ATInterstitialExListener() {
            @Override
            public void onDeeplinkCallback(ATAdInfo atAdInfo, boolean isSuccess) {
                MsgTools.printMsg("interstitial onDeeplinkCallback: " + mPlacementId);

                Map<String, Object> extraMap = new HashMap<>();
                extraMap.put(Const.CallbackKey.isDeeplinkSuccess, isSuccess);

                ATFlutterEventManager.getInstance().sendCallbackMsgToFlutter(
                        Const.CallbackMethodCall.InterstitialCall, Const.InterstitialCallback.DeeplinkCallbackKey,
                        mPlacementId, atAdInfo.toString(), null, extraMap);
            }

            @Override
            public void onDownloadConfirm(Context context, ATAdInfo atAdInfo, ATNetworkConfirmInfo atNetworkConfirmInfo) {
                MsgTools.printMsg("interstitial onDownloadConfirm: " + mPlacementId);
            }

            @Override
            public void onInterstitialAdLoaded() {
                MsgTools.printMsg("onInterstitialAdLoaded: " + mPlacementId);

                ATFlutterEventManager.getInstance().sendCallbackMsgToFlutter(
                        Const.CallbackMethodCall.InterstitialCall, Const.InterstitialCallback.LoadedCallbackKey,
                        mPlacementId, null, null);
            }

            @Override
            public void onInterstitialAdLoadFail(AdError adError) {
                MsgTools.printMsg("onInterstitialAdLoadFail: " + mPlacementId + ", " + adError.getFullErrorInfo());

                ATFlutterEventManager.getInstance().sendCallbackMsgToFlutter(
                        Const.CallbackMethodCall.InterstitialCall, Const.InterstitialCallback.LoadFailCallbackKey,
                        mPlacementId, null, adError.getFullErrorInfo());
            }

            @Override
            public void onInterstitialAdClicked(ATAdInfo atAdInfo) {
                MsgTools.printMsg("onInterstitialAdClicked: " + mPlacementId);

                ATFlutterEventManager.getInstance().sendCallbackMsgToFlutter(
                        Const.CallbackMethodCall.InterstitialCall, Const.InterstitialCallback.ClickCallbackKey,
                        mPlacementId, atAdInfo.toString(), null);
            }

            @Override
            public void onInterstitialAdShow(ATAdInfo atAdInfo) {
                MsgTools.printMsg("onInterstitialAdShow: " + mPlacementId);

                ATFlutterEventManager.getInstance().sendCallbackMsgToFlutter(
                        Const.CallbackMethodCall.InterstitialCall, Const.InterstitialCallback.ShowCallbackKey,
                        mPlacementId, atAdInfo.toString(), null);
            }

            @Override
            public void onInterstitialAdClose(ATAdInfo atAdInfo) {
                MsgTools.printMsg("onInterstitialAdClose: " + mPlacementId);

                ATFlutterEventManager.getInstance().sendCallbackMsgToFlutter(
                        Const.CallbackMethodCall.InterstitialCall, Const.InterstitialCallback.CloseCallbackKey,
                        mPlacementId, atAdInfo.toString(), null);
            }

            @Override
            public void onInterstitialAdVideoStart(ATAdInfo atAdInfo) {
                MsgTools.printMsg("onInterstitialAdVideoStart: " + mPlacementId);

                ATFlutterEventManager.getInstance().sendCallbackMsgToFlutter(
                        Const.CallbackMethodCall.InterstitialCall, Const.InterstitialCallback.PlayStartCallbackKey,
                        mPlacementId, atAdInfo.toString(), null);
            }

            @Override
            public void onInterstitialAdVideoEnd(ATAdInfo atAdInfo) {
                MsgTools.printMsg("onInterstitialAdVideoEnd: " + mPlacementId);

                ATFlutterEventManager.getInstance().sendCallbackMsgToFlutter(
                        Const.CallbackMethodCall.InterstitialCall, Const.InterstitialCallback.PlayEndCallbackKey,
                        mPlacementId, atAdInfo.toString(), null);
            }

            @Override
            public void onInterstitialAdVideoError(AdError adError) {
                MsgTools.printMsg("onInterstitialAdVideoError: " + mPlacementId + ", " + adError.getFullErrorInfo());

                ATFlutterEventManager.getInstance().sendCallbackMsgToFlutter(
                        Const.CallbackMethodCall.InterstitialCall, Const.InterstitialCallback.PlayFailCallbackKey,
                        mPlacementId, null, adError.getFullErrorInfo());
            }
        });

        mInterstitialAd.setAdSourceStatusListener(new ATAdSourceStatusListener() {
            @Override
            public void onAdSourceBiddingAttempt(ATAdInfo adInfo) {
                MsgTools.printMsg("onAdSourceBiddingAttempt: " + mPlacementId + ", " + (adInfo != null ? adInfo.getAdsourceId() : ""));

                ATFlutterEventManager.getInstance().sendAdSourceCallbackMsgToFlutter(
                        Const.CallbackMethodCall.InterstitialCall, Const.InterstitialCallback.AdSourceBiddingAttemptCallbackKey,
                        mPlacementId, adInfo, null);
            }

            @Override
            public void onAdSourceBiddingFilled(ATAdInfo adInfo) {
                MsgTools.printMsg("onAdSourceBiddingFilled: " + mPlacementId + ", " + (adInfo != null ? adInfo.getAdsourceId() : ""));

                ATFlutterEventManager.getInstance().sendAdSourceCallbackMsgToFlutter(
                        Const.CallbackMethodCall.InterstitialCall, Const.InterstitialCallback.AdSourceBiddingFilledCallbackKey,
                        mPlacementId, adInfo, null);
            }

            @Override
            public void onAdSourceBiddingFail(ATAdInfo adInfo, AdError adError) {
                MsgTools.printMsg("onAdSourceBiddingFail: " + mPlacementId + ", " + (adInfo != null ? adInfo.getAdsourceId() : ""));

                ATFlutterEventManager.getInstance().sendAdSourceCallbackMsgToFlutter(
                        Const.CallbackMethodCall.InterstitialCall, Const.InterstitialCallback.AdSourceBiddingFailCallbackKey,
                        mPlacementId, adInfo, adError);
            }

            @Override
            public void onAdSourceAttempt(ATAdInfo adInfo) {
                MsgTools.printMsg("onAdSourceAttempt: " + mPlacementId + ", " + (adInfo != null ? adInfo.getAdsourceId() : ""));

                ATFlutterEventManager.getInstance().sendAdSourceCallbackMsgToFlutter(
                        Const.CallbackMethodCall.InterstitialCall, Const.InterstitialCallback.AdSourceAttemptCallbackKey,
                        mPlacementId, adInfo, null);
            }

            @Override
            public void onAdSourceLoadFilled(ATAdInfo adInfo) {
                MsgTools.printMsg("onAdSourceLoadFilled: " + mPlacementId + ", " + (adInfo != null ? adInfo.getAdsourceId() : ""));

                ATFlutterEventManager.getInstance().sendAdSourceCallbackMsgToFlutter(
                        Const.CallbackMethodCall.InterstitialCall, Const.InterstitialCallback.AdSourceLoadFilledCallbackKey,
                        mPlacementId, adInfo, null);
            }

            @Override
            public void onAdSourceLoadFail(ATAdInfo adInfo, AdError adError) {
                MsgTools.printMsg("onAdSourceLoadFail: " + mPlacementId + ", " + (adInfo != null ? adInfo.getAdsourceId() : ""));

                ATFlutterEventManager.getInstance().sendAdSourceCallbackMsgToFlutter(
                        Const.CallbackMethodCall.InterstitialCall, Const.InterstitialCallback.AdSourceLoadFailCallbackKey,
                        mPlacementId, adInfo, adError);
            }
        });

        mInterstitialAd.setAdMultipleLoadedListener(new ATAdMultipleLoadedListener() {
            @Override
            public void onAdMultipleLoaded(ATRequestingInfo atRequestingInfo) {
                MsgTools.printMsg("onAdMultipleLoaded: " + mPlacementId);

                ATFlutterEventManager.getInstance().sendCallbackToFlutter(
                        Const.CallbackMethodCall.InterstitialCall, Const.InterstitialCallback.MultipleLoadedCallbackKey,
                        mPlacementId, Utils.getRequestingInfo(atRequestingInfo), null);
            }
        });

        //download
//        try {
//            if (ATSDK.isCnSDK()) {
//                mInterstitialAd.setAdDownloadListener(new ATAppDownloadListener() {
//                    @Override
//                    public void onDownloadStart(ATAdInfo atAdInfo, long totalBytes, long currBytes, String fileName, String appName) {
//                        MsgTools.printMsg("interstitial onDownloadStart: " + mPlacementId + ", " + totalBytes + ", " + currBytes + ", " + fileName + ", " + appName);
//
//                        ATFlutterEventManager.getInstance().sendDownloadMsgToFlutter(Const.CallbackMethodCall.DownloadCall, Const.DownloadCallCallback.DownloadStartKey,
//                                mPlacementId, atAdInfo.toString(), totalBytes, currBytes, fileName, appName);
//                    }
//
//                    @Override
//                    public void onDownloadUpdate(ATAdInfo atAdInfo, long totalBytes, long currBytes, String fileName, String appName) {
//                        MsgTools.printMsg("interstitial onDownloadUpdate: " + mPlacementId);
//
//                        ATFlutterEventManager.getInstance().sendDownloadMsgToFlutter(Const.CallbackMethodCall.DownloadCall, Const.DownloadCallCallback.DownloadUpdateKey,
//                                mPlacementId, atAdInfo.toString(), totalBytes, currBytes, fileName, appName);
//                    }
//
//                    @Override
//                    public void onDownloadPause(ATAdInfo atAdInfo, long totalBytes, long currBytes, String fileName, String appName) {
//                        MsgTools.printMsg("interstitial onDownloadPause: " + mPlacementId);
//
//                        ATFlutterEventManager.getInstance().sendDownloadMsgToFlutter(Const.CallbackMethodCall.DownloadCall, Const.DownloadCallCallback.DownloadPauseKey,
//                                mPlacementId, atAdInfo.toString(), totalBytes, currBytes, fileName, appName);
//                    }
//
//                    @Override
//                    public void onDownloadFinish(ATAdInfo atAdInfo, long totalBytes, String fileName, String appName) {
//                        MsgTools.printMsg("interstitial onDownloadFinish: " + mPlacementId + ", " + totalBytes + ", " + fileName + ", " + appName);
//
//                        ATFlutterEventManager.getInstance().sendDownloadMsgToFlutter(Const.CallbackMethodCall.DownloadCall, Const.DownloadCallCallback.DownloadFinishedKey,
//                                mPlacementId, atAdInfo.toString(), totalBytes, -1, fileName, appName);
//                    }
//
//                    @Override
//                    public void onDownloadFail(ATAdInfo atAdInfo, long totalBytes, long currBytes, String fileName, String appName) {
//                        MsgTools.printMsg("interstitial onDownloadFail: " + mPlacementId + ", " + totalBytes + ", " + currBytes + ", " + fileName + ", " + appName);
//
//                        ATFlutterEventManager.getInstance().sendDownloadMsgToFlutter(Const.CallbackMethodCall.DownloadCall, Const.DownloadCallCallback.DownloadFailedKey,
//                                mPlacementId, atAdInfo.toString(), totalBytes, currBytes, fileName, appName);
//                    }
//
//                    @Override
//                    public void onInstalled(ATAdInfo atAdInfo, String fileName, String appName) {
//                        MsgTools.printMsg("interstitial onInstalled: " + mPlacementId + ", " + fileName + ", " + appName);
//
//                        ATFlutterEventManager.getInstance().sendDownloadMsgToFlutter(Const.CallbackMethodCall.DownloadCall, Const.DownloadCallCallback.DownloadInstalledKey,
//                                mPlacementId, atAdInfo.toString(), -1, -1, fileName, appName);
//                    }
//                });
//            }
//        } catch (Throwable e) {
//        }
    }

    public void loadInterstitial(final String placementId, final Map<String, Object> settings) {
        MsgTools.printMsg("loadInterstitial: " + placementId + ", settings: " + settings);

        if (mInterstitialAd == null) {
            initInterstitial(placementId);
        }
        if (mInterstitialAd == null) {
            MsgTools.printMsg("loadInterstitial: mInterstitialAd null after init, placementId=" + placementId);
            return;
        }

        if (settings != null) {

            try {
                if (settings.containsKey(Const.Interstitial.UseRewardedVideoAsInterstitialKey)) {
                    if ((boolean) settings.get(Const.Interstitial.UseRewardedVideoAsInterstitialKey)) {

                        MsgTools.printMsg("loadInterstitial: " + placementId + ", is_use_rewarded_video_as_interstitial: " + true);
                        settings.put("is_use_rewarded_video_as_interstitial", true);
                    }
                }
            } catch (Throwable e) {
            }

            try {
                Map<String, Object> map = (Map<String, Object>) settings.get(Const.SIZE);
                if (map != null) {
                    Activity activity = FlutterPluginUtil.getActivity();
                    if (FlutterPluginUtil.isActivityUsable(activity)) {
                        int width = Utils.dip2px(activity, Double.parseDouble(map.get(Const.WIDTH).toString()));
                        int height = Utils.dip2px(activity, Double.parseDouble(map.get(Const.HEIGHT).toString()));

                        MsgTools.printMsg("loadInterstitial: " + placementId + ", width: " + width + ", height: " + height);

                        settings.put("key_width", width);
                        settings.put("key_height", height);
                    }
                }
            } catch (Throwable e) {
                e.printStackTrace();
            }
        }

        mInterstitialAd.setLocalExtra(settings);
        mInterstitialAd.load();
    }

    public void showInterstitialAd(final String scenario) {
        MsgTools.printMsg("showInterstitialAd: " + mPlacementId + ", scenario: " + scenario);

        if (mInterstitialAd != null) {
            Activity activity = FlutterPluginUtil.getActivity();
            if (!FlutterPluginUtil.isActivityUsable(activity)) {
                MsgTools.printMsg("showInterstitialAd: activity invalid, skip show");
                return;
            }
            if (!TextUtils.isEmpty(scenario)) {
                mInterstitialAd.show(activity, scenario);
            } else {
                mInterstitialAd.show(activity);
            }
        }
    }

    public void showConfigInterstitialAd(final String scenario, final String showCustomExt) {
        MsgTools.printMsg(" == showConfigInterstitialAd: " + mPlacementId + ", scenario: " + scenario + ", customShowExt: " + showCustomExt);

        if (mInterstitialAd != null) {
            Activity activity = FlutterPluginUtil.getActivity();
            if (!FlutterPluginUtil.isActivityUsable(activity)) {
                MsgTools.printMsg("showConfigInterstitialAd: activity invalid, skip show");
                return;
            }
            ATShowConfig.Builder builder = new ATShowConfig.Builder();
            if (!TextUtils.isEmpty(scenario)) {
                builder.scenarioId(scenario);
            }
            if (!TextUtils.isEmpty(showCustomExt)) {
                builder.showCustomExt(showCustomExt);
            }
            mInterstitialAd.show(activity, builder.build());
        }
    }

    public boolean isAdReady() {
        MsgTools.printMsg("interstitial isAdReady: " + mPlacementId);

        boolean isReady = false;
        if (mInterstitialAd != null) {
            isReady = mInterstitialAd.isAdReady();
        }

        MsgTools.printMsg("interstitial isAdReady: " + mPlacementId + ", " + isReady);
        return isReady;
    }

    public Map<String, Object> checkAdStatus() {
        MsgTools.printMsg("interstitial checkAdStatus: " + mPlacementId);

        Map<String, Object> map = new HashMap<>(5);

        if (mInterstitialAd != null) {
            ATAdStatusInfo atAdStatusInfo = mInterstitialAd.checkAdStatus();
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
        MsgTools.printMsg("interstitial checkValidAdCaches: " + mPlacementId);

        if (mInterstitialAd != null) {
            List<ATAdInfo> vaildAds = mInterstitialAd.checkValidAdCaches();
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
        MsgTools.printMsg("entryInterstitialScenario: " + mPlacementId + "sceneID: " + sceneID);
        ATInterstitial.entryAdScenario(placementId, sceneID);
    }
}
