package com.secmtp.flutter;

import android.text.TextUtils;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import com.secmtp.flutter.banner.ATAdBannerManger;
import com.secmtp.flutter.init.ATAdInitManger;
import com.secmtp.flutter.interstitial.ATAdInterstitialManger;
import com.secmtp.flutter.nativead.ATAdNativeManger;
import com.secmtp.flutter.reward.ATAdRewardVideoManger;
import com.secmtp.flutter.splash.ATAdSplashManger;
import com.secmtp.flutter.utils.Const;
import com.secmtp.flutter.utils.FlutterPluginUtil;
import com.secmtp.flutter.utils.MsgTools;
import com.secmtp.flutter.utils.Utils;
import com.secmtp.sdk.core.api.ATAdInfo;
import com.secmtp.sdk.core.api.AdError;

import java.util.HashMap;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.ThreadFactory;

import io.flutter.Log;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

public class ATFlutterEventManager {

    private static ATFlutterEventManager sInstance;

    private volatile MethodChannel mMethodChannel;
    private volatile BinaryMessenger mBinaryMessenger;

    private final ExecutorService singleExecutorService;

    private ATFlutterEventManager() {
        singleExecutorService = Executors.newSingleThreadExecutor(new ThreadFactory() {
            @Override
            public Thread newThread(Runnable r) {
                Thread thread = Executors.defaultThreadFactory().newThread(r);
                thread.setName("tu_flutter_work");
                return thread;
            }
        });
    }

    public synchronized static ATFlutterEventManager getInstance() {
        if (sInstance == null) {
            sInstance = new ATFlutterEventManager();
        }
        return sInstance;
    }

    public void init(BinaryMessenger binaryMessenger) {
        if (binaryMessenger == null) {
            return;
        }
        //If it is the same messenger and the channel has not been released, return directly
        if (mMethodChannel != null && mBinaryMessenger == binaryMessenger) {
            return;
        }
        // If there are old channels, clean them up first
        if (mMethodChannel != null) {
            mMethodChannel.setMethodCallHandler(null);
        }

        mBinaryMessenger = binaryMessenger;
        mMethodChannel = new MethodChannel(binaryMessenger, "secmtp_sdk");
        mMethodChannel.setMethodCallHandler(new MethodChannel.MethodCallHandler() {
            @Override
            public void onMethodCall(@NonNull MethodCall methodCall, @NonNull MethodChannel.Result result) {
                //receive message from flutter
                try {
                    if (Utils.checkMethodInArray(Const.initMethodNames, methodCall.method)) {
                        ATAdInitManger.getInstance().handleMethodCall(methodCall, result);
                    } else if (Utils.checkMethodInArray(Const.rewardVideoMethodNames, methodCall.method)) {
                        ATAdRewardVideoManger.getInstance().handleMethodCall(methodCall, result);
                    } else if (Utils.checkMethodInArray(Const.interstitialMethodNames, methodCall.method)) {
                        ATAdInterstitialManger.getInstance().handleMethodCall(methodCall, result);
                    } else if (Utils.checkMethodInArray(Const.bannerMethodNames, methodCall.method)) {
                        ATAdBannerManger.getInstance().handleMethodCall(methodCall, result);
                    } else if (Utils.checkMethodInArray(Const.nativeMethodNames, methodCall.method)) {
                        ATAdNativeManger.getInstance().handleMethodCall(methodCall, result);
                    } else if (Utils.checkMethodInArray(Const.splashMethodNames, methodCall.method)) {
                        ATAdSplashManger.getInstance().handleMethodCall(methodCall, result);
                    } else {
                        result.notImplemented();
                    }

                } catch (Throwable e) {
                    MsgTools.printMsg("method call error: " + methodCall + ", " + e.getMessage());
                    e.printStackTrace();
                    result.error("TOPON_NATIVE_ERROR", e.getMessage(), null);
                }
            }
        });
    }

    // Check if the channel is available
    public boolean isChannelAvailable() {
        return mMethodChannel != null;
    }

    public void sendDownloadMsgToFlutter(final String callName, String callbackName, String placementId, String atAdInfoString,
                                         long totalBytes, long currBytes, String fileName, String appName) {

        try {
            final Map<String, Object> paramsMap = new HashMap<>(10);
            paramsMap.put("callbackName", callbackName);
            paramsMap.put("placementID", placementId);

            if (atAdInfoString != null) {
                paramsMap.put("extraDic", Utils.jsonStrToMap(atAdInfoString));
            }

            if (totalBytes > 0) {
                paramsMap.put("totalBytes", totalBytes);
            }
            if (currBytes > 0) {
                paramsMap.put("currBytes", currBytes);
            }
            if (fileName != null) {
                paramsMap.put("fileName", fileName);
            }
            if (appName != null) {
                paramsMap.put("appName", appName);
            }

            FlutterPluginUtil.runOnUiThread(new Runnable() {
                @Override
                public void run() {
                    try {
                        if (mMethodChannel != null) {
                            mMethodChannel.invokeMethod(callName, paramsMap);
                        }
                    } catch (Throwable e) {
                        Log.e(MsgTools.TAG, "sendCallbackMsgToFlutter invokeMethod error: " + callName + ", " + e.getMessage());
                        e.printStackTrace();
                    }
                }
            });

        } catch (Throwable e) {
            Log.e(MsgTools.TAG, "sendCallbackMsgToFlutter error: " + callbackName + ", " + e.getMessage());
            e.printStackTrace();
        }
    }


    public void sendCallbackMsgToFlutter(final String callName, String callbackName, String placementId, Object infoObj, String errorMsg, Map<String, Object> extra) {

        try {
            final Map<String, Object> paramsMap = new HashMap<>(8);
            paramsMap.put(Const.CallbackKey.callbackName, callbackName);
            paramsMap.put(Const.CallbackKey.placementID, placementId);

            if (infoObj instanceof String) {
                paramsMap.put(Const.CallbackKey.extraDic, Utils.jsonStrToMap(((String) infoObj)));
            } else if (infoObj instanceof Map) {
                paramsMap.put(Const.CallbackKey.extraDic, infoObj);
            }

            if (errorMsg != null) {
                paramsMap.put(Const.CallbackKey.requestMessage, errorMsg);
            } else {
                paramsMap.put(Const.CallbackKey.requestMessage, "");
            }

            try {
                if (extra != null) {
                    Set<Map.Entry<String, Object>> entries = extra.entrySet();
                    for (Map.Entry<String, Object> entry : entries) {
                        String key = entry.getKey();
                        Object value = entry.getValue();

                        if (value instanceof Boolean) {
                            if (TextUtils.equals(key, Const.CallbackKey.isDeeplinkSuccess) || TextUtils.equals(key, Const.CallbackKey.isTimeout)) {
                                paramsMap.put(key, ((Boolean) value));
                            }
                        }
                    }
                }
            } catch (Throwable e) {
                e.printStackTrace();
            }

            FlutterPluginUtil.runOnUiThread(new Runnable() {
                @Override
                public void run() {
                    try {
                        if (mMethodChannel != null) {
                            mMethodChannel.invokeMethod(callName, paramsMap);
                        }
                    } catch (Throwable e) {
                        Log.e(MsgTools.TAG, "sendCallbackMsgToFlutter invokeMethod error: " + callName + ", " + e.getMessage());
                        e.printStackTrace();
                    }
                }
            });

        } catch (Throwable e) {
            Log.e(MsgTools.TAG, "sendCallbackMsgToFlutter error: " + callbackName + ", " + e.getMessage());
            e.printStackTrace();
        }
    }


    /**
     * send message to flutter
     */
    public void sendCallbackMsgToFlutter(String callName, String callbackName, String placementId, String atAdInfoString, String errorMsg) {
        this.sendCallbackMsgToFlutter(callName, callbackName, placementId, atAdInfoString, errorMsg, null);
    }
    public void sendCallbackToFlutter(String callName, String callbackName, String placementId, Map<String, Object> infoMap, String errorMsg) {
        this.sendCallbackMsgToFlutter(callName, callbackName, placementId, infoMap, errorMsg, null);
    }

    public void sendAdSourceCallbackMsgToFlutter(String callName, String callbackName, String placementId, ATAdInfo adInfo, AdError adError) {
        if (singleExecutorService != null) {
            singleExecutorService.execute(new Runnable() {
                @Override
                public void run() {
                    sendCallbackMsgToFlutter(callName, callbackName, placementId, adInfo != null ? adInfo.toString() : null,
                            adError != null ? adError.getFullErrorInfo() : null, null);
                }
            });
        }
    }


    /**
     * send message to flutter
     */
    public void sendMsgToFlutter(final String callName, String key, Object extra) {
        try {
            final Map<String, Object> paramsMap = new HashMap<>(4);
            paramsMap.put(key, extra);


            FlutterPluginUtil.runOnUiThread(new Runnable() {
                @Override
                public void run() {
                    try {
                        if (mMethodChannel != null) {
                            mMethodChannel.invokeMethod(callName, paramsMap);
                        }
                    } catch (Throwable e) {
                        Log.e(MsgTools.TAG, "sendMsgToFlutter invokeMethod error: " + key + ", " + e.getMessage());
                        e.printStackTrace();
                    }
                }
            });
        } catch (Throwable e) {
            Log.e(MsgTools.TAG, "sendMsgToFlutter error: " + key + ", " + e.getMessage());
            e.printStackTrace();
        }
    }

    public void release() {
        if (mMethodChannel != null) {
            mMethodChannel.setMethodCallHandler(null);
            mMethodChannel = null;
        }
        mBinaryMessenger = null;
    }

    /**
     * Only release the channels "currently bound to this messenger". When there are multiple FlutterEngines,
     * the detach of the background engine should not clear the channels of the main UI engine
     */
    public void releaseForMessenger(@Nullable BinaryMessenger messenger) {
        if (messenger != null && mBinaryMessenger == messenger) {
            release();
        }
    }

}
