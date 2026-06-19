package com.secmtp.flutter.banner;

import android.app.Activity;
import android.content.Context;
import android.os.Build;
import android.text.TextUtils;
import android.view.Gravity;
import android.view.View;
import android.view.ViewGroup;
import android.view.ViewParent;
import android.widget.FrameLayout;

//import com.anythink.china.api.ATAppDownloadListener;

//import com.anythink.core.api.ATSDK;
import com.secmtp.flutter.ATFlutterEventManager;
import com.secmtp.flutter.SecmtpSdkPlugin;
import com.secmtp.flutter.utils.Const;
import com.secmtp.flutter.utils.FlutterPluginUtil;
import com.secmtp.flutter.utils.MsgTools;
import com.secmtp.flutter.utils.Utils;
import com.secmtp.sdk.banner.api.ATBannerExListener;
import com.secmtp.sdk.banner.api.ATBannerView;
import com.secmtp.sdk.core.api.ATAdInfo;
import com.secmtp.sdk.core.api.ATAdMultipleLoadedListener;
import com.secmtp.sdk.core.api.ATAdSourceStatusListener;
import com.secmtp.sdk.core.api.ATAdStatusInfo;
import com.secmtp.sdk.core.api.ATNetworkConfirmInfo;
import com.secmtp.sdk.core.api.ATRequestingInfo;
import com.secmtp.sdk.core.api.ATShowConfig;
import com.secmtp.sdk.core.api.AdError;

import org.json.JSONArray;
import org.json.JSONObject;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class ATBannerHelper extends SecmtpSdkPlugin {

    Activity mActivity;
    String mPlacementId;
    ATBannerView mBannerView;

    public ATBannerHelper() {
        mActivity = FlutterPluginUtil.getActivity();
    }

    /** Synchronizes with the current Flutter Activity; the old Activity may have been destroyed <p/>
     * after returning from the background/multitasking, so you must refresh and addContentView again. */
    private void refreshActivity() {
        Activity a = FlutterPluginUtil.getActivity();
        if (a != null) {
            mActivity = a;
        }
    }

    private boolean isActivityUsable() {
        if (mActivity == null) {
            return false;
        }
        if (mActivity.isFinishing()) {
            return false;
        }
        return Build.VERSION.SDK_INT < Build.VERSION_CODES.JELLY_BEAN_MR1 || !mActivity.isDestroyed();
    }

    private static int getIntValueSafe(Object object) {
        if (object == null) {
            return 0;
        }
        if (object instanceof Number) {
            return ((Number) object).intValue();
        }
        try {
            return (int) Double.parseDouble(object.toString());
        } catch (Throwable e) {
            return 0;
        }
    }

    public void initBanner(String placementId) {
        refreshActivity();
        mPlacementId = placementId;
        if (mActivity == null) {
            MsgTools.printMsg("initBanner: activity null, placementId=" + placementId);
            return;
        }
        mBannerView = new ATBannerView(mActivity);
        mBannerView.setPlacementId(mPlacementId);
        mBannerView.setBannerAdListener(new ATBannerExListener() {
            @Override
            public void onDeeplinkCallback(boolean isRefresh, ATAdInfo atAdInfo, boolean isSuccess) {
                MsgTools.printMsg("banner onDeeplinkCallback: " + mPlacementId);

                Map<String, Object> extraMap = new HashMap<>();
                extraMap.put(Const.CallbackKey.isDeeplinkSuccess, isSuccess);

                ATFlutterEventManager.getInstance().sendCallbackMsgToFlutter(
                        Const.CallbackMethodCall.BannerCall, Const.BannerCallback.DeeplinkCallbackKey,
                        mPlacementId, atAdInfo.toString(), null, extraMap);
            }

            @Override
            public void onDownloadConfirm(Context context, ATAdInfo atAdInfo, ATNetworkConfirmInfo atNetworkConfirmInfo) {
                MsgTools.printMsg("banner onDownloadConfirm: " + mPlacementId);
            }

            @Override
            public void onBannerLoaded() {
                MsgTools.printMsg("onBannerLoaded: " + mPlacementId);

                ATFlutterEventManager.getInstance().sendCallbackMsgToFlutter(
                        Const.CallbackMethodCall.BannerCall, Const.BannerCallback.LoadedCallbackKey,
                        mPlacementId, null, null);
            }

            @Override
            public void onBannerFailed(AdError adError) {
                MsgTools.printMsg("onBannerFailed: " + mPlacementId + ", " + adError.getFullErrorInfo());

                ATFlutterEventManager.getInstance().sendCallbackMsgToFlutter(
                        Const.CallbackMethodCall.BannerCall, Const.BannerCallback.LoadFailCallbackKey,
                        mPlacementId, null, adError.getFullErrorInfo());
            }

            @Override
            public void onBannerClicked(ATAdInfo atAdInfo) {
                MsgTools.printMsg("onBannerClicked: " + mPlacementId);

                ATFlutterEventManager.getInstance().sendCallbackMsgToFlutter(
                        Const.CallbackMethodCall.BannerCall, Const.BannerCallback.ClickCallbackKey,
                        mPlacementId, atAdInfo.toString(), null);
            }

            @Override
            public void onBannerShow(ATAdInfo atAdInfo) {
                MsgTools.printMsg("onBannerShow: " + mPlacementId);

                ATFlutterEventManager.getInstance().sendCallbackMsgToFlutter(
                        Const.CallbackMethodCall.BannerCall, Const.BannerCallback.ShowCallbackKey,
                        mPlacementId, atAdInfo.toString(), null);
            }

            @Override
            public void onBannerClose(ATAdInfo atAdInfo) {
                MsgTools.printMsg("onBannerClose: " + mPlacementId);

                ATFlutterEventManager.getInstance().sendCallbackMsgToFlutter(
                        Const.CallbackMethodCall.BannerCall, Const.BannerCallback.CloseCallbackKey,
                        mPlacementId, atAdInfo.toString(), null);
            }

            @Override
            public void onBannerAutoRefreshed(ATAdInfo atAdInfo) {
                MsgTools.printMsg("onBannerAutoRefreshed: " + mPlacementId);

                ATFlutterEventManager.getInstance().sendCallbackMsgToFlutter(
                        Const.CallbackMethodCall.BannerCall, Const.BannerCallback.RefreshCallbackKey,
                        mPlacementId, atAdInfo.toString(), null);
            }

            @Override
            public void onBannerAutoRefreshFail(AdError adError) {
                MsgTools.printMsg("onBannerAutoRefreshFail: " + mPlacementId + ", " + adError.getFullErrorInfo());

                ATFlutterEventManager.getInstance().sendCallbackMsgToFlutter(
                        Const.CallbackMethodCall.BannerCall, Const.BannerCallback.RefreshFailCallbackKey,
                        mPlacementId, null, adError.getFullErrorInfo());
            }
        });

        mBannerView.setAdSourceStatusListener(new ATAdSourceStatusListener() {
            @Override
            public void onAdSourceBiddingAttempt(ATAdInfo adInfo) {
                MsgTools.printMsg("onAdSourceBiddingAttempt: " + mPlacementId + ", " + (adInfo != null ? adInfo.getAdsourceId() : ""));

                ATFlutterEventManager.getInstance().sendAdSourceCallbackMsgToFlutter(
                        Const.CallbackMethodCall.BannerCall, Const.BannerCallback.AdSourceBiddingAttemptCallbackKey,
                        mPlacementId, adInfo, null);
            }

            @Override
            public void onAdSourceBiddingFilled(ATAdInfo adInfo) {
                MsgTools.printMsg("onAdSourceBiddingFilled: " + mPlacementId + ", " + (adInfo != null ? adInfo.getAdsourceId() : ""));

                ATFlutterEventManager.getInstance().sendAdSourceCallbackMsgToFlutter(
                        Const.CallbackMethodCall.BannerCall, Const.BannerCallback.AdSourceBiddingFilledCallbackKey,
                        mPlacementId, adInfo, null);
            }

            @Override
            public void onAdSourceBiddingFail(ATAdInfo adInfo, AdError adError) {
                MsgTools.printMsg("onAdSourceBiddingFail: " + mPlacementId + ", " + (adInfo != null ? adInfo.getAdsourceId() : ""));

                ATFlutterEventManager.getInstance().sendAdSourceCallbackMsgToFlutter(
                        Const.CallbackMethodCall.BannerCall, Const.BannerCallback.AdSourceBiddingFailCallbackKey,
                        mPlacementId, adInfo, adError);
            }

            @Override
            public void onAdSourceAttempt(ATAdInfo adInfo) {
                MsgTools.printMsg("onAdSourceAttempt: " + mPlacementId + ", " + (adInfo != null ? adInfo.getAdsourceId() : ""));

                ATFlutterEventManager.getInstance().sendAdSourceCallbackMsgToFlutter(
                        Const.CallbackMethodCall.BannerCall, Const.BannerCallback.AdSourceAttemptCallbackKey,
                        mPlacementId, adInfo, null);
            }

            @Override
            public void onAdSourceLoadFilled(ATAdInfo adInfo) {
                MsgTools.printMsg("onAdSourceLoadFilled: " + mPlacementId + ", " + (adInfo != null ? adInfo.getAdsourceId() : ""));

                ATFlutterEventManager.getInstance().sendAdSourceCallbackMsgToFlutter(
                        Const.CallbackMethodCall.BannerCall, Const.BannerCallback.AdSourceLoadFilledCallbackKey,
                        mPlacementId, adInfo, null);
            }

            @Override
            public void onAdSourceLoadFail(ATAdInfo adInfo, AdError adError) {
                MsgTools.printMsg("onAdSourceLoadFail: " + mPlacementId + ", " + (adInfo != null ? adInfo.getAdsourceId() : ""));

                ATFlutterEventManager.getInstance().sendAdSourceCallbackMsgToFlutter(
                        Const.CallbackMethodCall.BannerCall, Const.BannerCallback.AdSourceLoadFailCallbackKey,
                        mPlacementId, adInfo, adError);
            }
        });

        mBannerView.setAdMultipleLoadedListener(new ATAdMultipleLoadedListener() {
            @Override
            public void onAdMultipleLoaded(ATRequestingInfo atRequestingInfo) {
                MsgTools.printMsg("onAdMultipleLoaded: " + mPlacementId);

                ATFlutterEventManager.getInstance().sendCallbackToFlutter(
                        Const.CallbackMethodCall.BannerCall, Const.BannerCallback.MultipleLoadedCallbackKey,
                        mPlacementId, Utils.getRequestingInfo(atRequestingInfo), null);
            }
        });

        //download
//        try {
//            if (ATSDK.isCnSDK()) {
//                mBannerView.setAdDownloadListener(new ATAppDownloadListener() {
//                    @Override
//                    public void onDownloadStart(ATAdInfo atAdInfo, long totalBytes, long currBytes, String fileName, String appName) {
//                        MsgTools.printMsg("banner onDownloadStart: " + mPlacementId + ", " + totalBytes + ", " + currBytes + ", " + fileName + ", " + appName);
//
//                        ATFlutterEventManager.getInstance().sendDownloadMsgToFlutter(Const.CallbackMethodCall.DownloadCall, Const.DownloadCallCallback.DownloadStartKey,
//                                mPlacementId, atAdInfo.toString(), totalBytes, currBytes, fileName, appName);
//                    }
//
//                    @Override
//                    public void onDownloadUpdate(ATAdInfo atAdInfo, long totalBytes, long currBytes, String fileName, String appName) {
//                        MsgTools.printMsg("banner onDownloadUpdate: " + mPlacementId);
//
//                        ATFlutterEventManager.getInstance().sendDownloadMsgToFlutter(Const.CallbackMethodCall.DownloadCall, Const.DownloadCallCallback.DownloadUpdateKey,
//                                mPlacementId, atAdInfo.toString(), totalBytes, currBytes, fileName, appName);
//                    }
//
//                    @Override
//                    public void onDownloadPause(ATAdInfo atAdInfo, long totalBytes, long currBytes, String fileName, String appName) {
//                        MsgTools.printMsg("banner onDownloadPause: " + mPlacementId);
//
//                        ATFlutterEventManager.getInstance().sendDownloadMsgToFlutter(Const.CallbackMethodCall.DownloadCall, Const.DownloadCallCallback.DownloadPauseKey,
//                                mPlacementId, atAdInfo.toString(), totalBytes, currBytes, fileName, appName);
//                    }
//
//                    @Override
//                    public void onDownloadFinish(ATAdInfo atAdInfo, long totalBytes, String fileName, String appName) {
//                        MsgTools.printMsg("banner onDownloadFinish: " + mPlacementId + ", " + totalBytes + ", " + fileName + ", " + appName);
//
//                        ATFlutterEventManager.getInstance().sendDownloadMsgToFlutter(Const.CallbackMethodCall.DownloadCall, Const.DownloadCallCallback.DownloadFinishedKey,
//                                mPlacementId, atAdInfo.toString(), totalBytes, -1, fileName, appName);
//                    }
//
//                    @Override
//                    public void onDownloadFail(ATAdInfo atAdInfo, long totalBytes, long currBytes, String fileName, String appName) {
//                        MsgTools.printMsg("banner onDownloadFail: " + mPlacementId + ", " + totalBytes + ", " + currBytes + ", " + fileName + ", " + appName);
//
//                        ATFlutterEventManager.getInstance().sendDownloadMsgToFlutter(Const.CallbackMethodCall.DownloadCall, Const.DownloadCallCallback.DownloadFailedKey,
//                                mPlacementId, atAdInfo.toString(), totalBytes, currBytes, fileName, appName);
//                    }
//
//                    @Override
//                    public void onInstalled(ATAdInfo atAdInfo, String fileName, String appName) {
//                        MsgTools.printMsg("banner onInstalled: " + mPlacementId + ", " + fileName + ", " + appName);
//
//                        ATFlutterEventManager.getInstance().sendDownloadMsgToFlutter(Const.CallbackMethodCall.DownloadCall, Const.DownloadCallCallback.DownloadInstalledKey,
//                                mPlacementId, atAdInfo.toString(), -1, -1, fileName, appName);
//                    }
//                });
//            }
//        } catch (Throwable e) {
//        }
    }

    public void loadBanner(final String placementId, final Map<String, Object> settings) {
        MsgTools.printMsg("loadBanner: " + placementId + ", settings: " + settings);

        FlutterPluginUtil.runOnUiThread(new Runnable() {
            @Override
            public void run() {
                refreshActivity();
                if (mBannerView == null) {
                    initBanner(placementId);
                }
                if (mBannerView == null) {
                    MsgTools.printMsg("loadBanner: mBannerView null after init, placementId=" + placementId);
                    return;
                }

                if (settings != null) {
                    try {
                        Map<String, Object> map = (Map<String, Object>) settings.get(Const.SIZE);
                        int width = Utils.dip2px(mActivity, Double.parseDouble(map.get(Const.WIDTH).toString()));
                        int height = Utils.dip2px(mActivity, Double.parseDouble(map.get(Const.HEIGHT).toString()));

                        if (mBannerView != null) {
                            if (mBannerView.getLayoutParams() == null) {
                                FrameLayout.LayoutParams lp = new FrameLayout.LayoutParams(width, height);
                                mBannerView.setLayoutParams(lp);
                            } else {
                                mBannerView.getLayoutParams().width = width;
                                mBannerView.getLayoutParams().height = height;
                            }

                            MsgTools.printMsg("loadBanner: " + mPlacementId + ", width: " + width + ", height: " + height);

                            settings.put("key_width", width);
                            settings.put("key_height", height);
                        }
                    } catch (Throwable e) {
                        e.printStackTrace();
                    }

                    try {
                        Object adaptiveWidthObject = settings.get(Const.Banner.adaptiveWidth);
                        if (adaptiveWidthObject != null) {
                            int width = Utils.dip2px(mActivity, Double.parseDouble(adaptiveWidthObject.toString()));
                            MsgTools.printMsg("loadBanner: " + mPlacementId + ", adaptiveWidth: " + width);
                            settings.put("adaptive_width", width);
                        }
                    } catch (Throwable e) {
                    }

                    try {
                        Object adaptiveOrientationObject = settings.get(Const.Banner.adaptiveOrientation);
                        if (adaptiveOrientationObject != null) {
                            int orientation = Utils.dip2px(mActivity, Integer.parseInt(adaptiveOrientationObject.toString()));
                            MsgTools.printMsg("loadBanner: " + mPlacementId + ", adaptiveOrientation: " + orientation);
                            settings.put("adaptive_orientation", orientation);
                        }
                    } catch (Throwable e) {
                        e.printStackTrace();
                    }

                }
                mBannerView.setLocalExtra(settings);

                mBannerView.loadAd();
            }
        });
    }


    public boolean isAdReady() {
        MsgTools.printMsg("banner isAdReady: " + mPlacementId);

        boolean isReady = false;
        if (mBannerView != null) {
            ATAdStatusInfo atAdStatusInfo = mBannerView.checkAdStatus();
            if (atAdStatusInfo != null) {
                isReady = atAdStatusInfo.isReady();
            }
        }
        MsgTools.printMsg("banner isAdReady: " + mPlacementId + ", " + isReady);
        return isReady;
    }

    public Map<String, Object> checkAdStatus() {
        MsgTools.printMsg("banner checkAdStatus: " + mPlacementId);

        Map<String, Object> map = new HashMap<>(5);

        if (mBannerView != null) {
            ATAdStatusInfo atAdStatusInfo = mBannerView.checkAdStatus();
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
        MsgTools.printMsg("banner checkValidAdCaches: " + mPlacementId);

        if (mBannerView != null) {
            List<ATAdInfo> vaildAds = mBannerView.checkValidAdCaches();
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


    public ATBannerView getBannerView() {
        return mBannerView;
    }

    public void showBannerWithRect(final Map<String, Object> settings, final String scenarioParam) {

        MsgTools.printMsg("showBannerWithRect: " + mPlacementId + ", scenario: " + scenarioParam);

        String scenario = scenarioParam;
        if (TextUtils.isEmpty(scenario)) {
            scenario = "";
        }

        if (settings == null) {
            MsgTools.printMsg("showBannerWithRect: settings null, skip");
            return;
        }

        String showCustomExtInMap = (String) settings.get(Const.SHOW_CUSTOM_EXT);
        if (TextUtils.isEmpty(showCustomExtInMap)) {
            showCustomExtInMap = "";
        }

        if (mBannerView != null) {

            int x = 0;
            int y = 0;
            int width = 0;
            int height = 0;

            Map<String, Object> size = (Map<String, Object>) settings.get(Const.SIZE);
            if (size != null) {
                x = getIntValueSafe(size.get(Const.X));
                y = getIntValueSafe(size.get(Const.Y));
                width = getIntValueSafe(size.get(Const.WIDTH));
                height = getIntValueSafe(size.get(Const.HEIGHT));
            }

            final int finalX = x;
            final int finalY = y;
            final int finalWidth = width;
            final int finalHeight = height;
            final String finalShowCustomExtInMap = showCustomExtInMap;
            final String finalScenario = scenario;

            FlutterPluginUtil.runOnUiThread(new Runnable() {
                @Override
                public void run() {
                    refreshActivity();
                    if (!isActivityUsable()) {
                        MsgTools.printMsg("showBannerWithRect: activity invalid, skip show");
                        return;
                    }
                    if (mBannerView == null) {
                        return;
                    }

                    ViewGroup.LayoutParams existingLp = mBannerView.getLayoutParams();
                    int widthPx;
                    int heightPx;
                    if (existingLp != null && existingLp.width > 0) {
                        widthPx = existingLp.width;
                    } else if (finalWidth > 0) {
                        widthPx = Utils.dip2px(mActivity, finalWidth);
                    } else {
                        widthPx = FrameLayout.LayoutParams.WRAP_CONTENT;
                    }
                    if (existingLp != null && existingLp.height > 0) {
                        heightPx = existingLp.height;
                    } else if (finalHeight > 0) {
                        heightPx = Utils.dip2px(mActivity, finalHeight);
                    } else {
                        heightPx = FrameLayout.LayoutParams.WRAP_CONTENT;
                    }

                    FrameLayout.LayoutParams layoutParams = new FrameLayout.LayoutParams(widthPx, heightPx);
                    layoutParams.leftMargin = finalX;
                    layoutParams.topMargin = finalY;
                    if (mBannerView.getParent() != null) {
                        ((ViewGroup) mBannerView.getParent()).removeView(mBannerView);
                    }

                    ATShowConfig.Builder builder = new ATShowConfig.Builder();
                    builder.scenarioId(finalScenario);
                    builder.showCustomExt(finalShowCustomExtInMap);
                    mBannerView.setShowConfig(builder.build());
                    MsgTools.printMsg("showBannerWithRect x: " + finalX + " y:" + finalY + " w:" + finalWidth + " h:" + finalHeight + " scenario:" + finalScenario + " finalShowCustomExtInMap:" + finalShowCustomExtInMap);
                    mActivity.addContentView(mBannerView, layoutParams);
                }
            });
        }
    }

    public void showBannerWithPosition(final String position, final String scenarioParam, final String showCustomExtParam) {
        MsgTools.printMsg("showBannerWithPosition: " + mPlacementId + ", scenario: " + scenarioParam + ", showCustomExt: " + showCustomExtParam);

        FlutterPluginUtil.runOnUiThread(new Runnable() {
            @Override
            public void run() {
                refreshActivity();
                if (!isActivityUsable()) {
                    MsgTools.printMsg("showBannerWithPosition: activity invalid, skip show");
                    return;
                }
                if (mBannerView != null) {
                    ViewGroup.LayoutParams existingLp = mBannerView.getLayoutParams();
                    int width = existingLp != null ? existingLp.width : FrameLayout.LayoutParams.WRAP_CONTENT;
                    int height = existingLp != null ? existingLp.height : FrameLayout.LayoutParams.WRAP_CONTENT;
                    if (width <= 0) {
                        width = FrameLayout.LayoutParams.WRAP_CONTENT;
                    }
                    if (height <= 0) {
                        height = FrameLayout.LayoutParams.WRAP_CONTENT;
                    }
                    FrameLayout.LayoutParams layoutParams = new FrameLayout.LayoutParams(width, height);
                    if (position.equals(Const.POSITION_TOP)) {
                        layoutParams.gravity = Gravity.CENTER_HORIZONTAL | Gravity.TOP;
                    } else {
                        layoutParams.gravity = Gravity.CENTER_HORIZONTAL | Gravity.BOTTOM;
                    }

                    String scenario = scenarioParam;
                    if (TextUtils.isEmpty(scenario)) {
                        scenario = "";
                    }

                    String showCustomExt = showCustomExtParam;
                    if (TextUtils.isEmpty(showCustomExt)) {
                        showCustomExt = "";
                    }

                    ATShowConfig.Builder builder = new ATShowConfig.Builder();
                    builder.scenarioId(scenario);
                    builder.showCustomExt(showCustomExt);
                    mBannerView.setShowConfig(builder.build());
                    mActivity.addContentView(mBannerView, layoutParams);
                }
            }
        });
    }

    public void reshowBanner() {
        MsgTools.printMsg("reshowBanner: " + mPlacementId);

        FlutterPluginUtil.runOnUiThread(new Runnable() {
            @Override
            public void run() {
                if (mBannerView != null) {
                    mBannerView.setVisibility(View.VISIBLE);
                } else {
                    MsgTools.printMsg("reshowBanner error, you must call loadBanner first, placementId: " + mPlacementId);
                }
            }
        });
    }

    public void hideBanner() {
        MsgTools.printMsg("hideBanner: " + mPlacementId);

        FlutterPluginUtil.runOnUiThread(new Runnable() {
            @Override
            public void run() {
                if (mBannerView != null) {
                    mBannerView.setVisibility(View.GONE);
                } else {
                    MsgTools.printMsg("hideBanner error, you must call loadBanner first, placementId: " + mPlacementId);
                }
            }
        });
    }

    public void removeBanner() {
        MsgTools.printMsg("removeBanner: " + mPlacementId);

        FlutterPluginUtil.runOnUiThread(new Runnable() {
            @Override
            public void run() {
                if (mBannerView != null) {
                    if (mBannerView.getParent() != null) {
                        ViewParent viewParent = mBannerView.getParent();
                        ((ViewGroup) viewParent).removeView(mBannerView);
                    }
                } else {
                    MsgTools.printMsg("removeBanner error, you must call loadBanner first, placementId: " + mPlacementId);
                }
            }
        });
    }

    public void entryScenario(final String placementId,final String sceneID) {
        MsgTools.printMsg("entryBannerScenario: " + mPlacementId + "sceneID: " + sceneID);
        ATBannerView.entryAdScenario(placementId, sceneID);
    }

}
