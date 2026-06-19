package com.secmtp.flutter.utils;

import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Paint;
import android.graphics.Path;
import android.graphics.PorterDuff;
import android.graphics.PorterDuffXfermode;

import com.secmtp.sdk.core.api.ATAdInfo;
import com.secmtp.sdk.core.api.ATRequestingInfo;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;

public class Utils {
    public static boolean checkMethodInArray(String[] methodArray, String methodName) {
        for (String method : methodArray) {
            if (method.equals(methodName))
                return true;
        }
        return false;
    }

    public static int dip2px(Context context, double dipValue) {
        float scale = context.getResources().getDisplayMetrics().density;
        return (int) (dipValue * scale + 0.5);
    }

    public static Map<String, Object> jsonStrToMap(String jsonStr) throws JSONException {
        Map<String, Object> data = new HashMap<>();
        try {
            JSONObject jsonObject = new JSONObject(jsonStr);
            Iterator<String> keys = jsonObject.keys();
            String key;
            while (keys.hasNext()) {
                key = keys.next();
                Object value = jsonObject.opt(key);

                if (value instanceof JSONArray) {
                    try {
                        data.put(key, value.toString());
                    } catch (Throwable e) {
                        e.printStackTrace();
                    }
                } else if (value instanceof JSONObject) {
                    try {
                        data.put(key, ((JSONObject) value).toString());
                    } catch (Throwable e) {
                        e.printStackTrace();
                    }
                } else if (value instanceof Map) {
                    try {
                        data.put(key, new JSONObject(((Map) value).toString()));
                    } catch (Throwable e) {
                        e.printStackTrace();
                    }
                } else {
                    data.put(key, value);
                }
            }
        } catch (Throwable e) {
            e.printStackTrace();
        }
        return data;
    }

    public static int getResId(Context context, String resName, String resType) {
        if (context != null) {
            resName = "secmtp_" + resName;
            return context.getResources().getIdentifier(resName, resType,
                    context.getPackageName());
        }
        return -1;
    }

    public static String mapToJsonString(Map<String, Object> map) {
        try {
            return new JSONObject(map).toString();
        } catch (Throwable e) {
        }
        return "";
    }

    public static Map<String, Object> getRequestingInfo(ATRequestingInfo requestingInfo) {
        if (requestingInfo == null) {
            return new HashMap<>();
        }

        List<ATAdInfo> biddingAttemptAdInfoList = requestingInfo.getBiddingAttemptAdInfoList();
        List<ATAdInfo> loadingAdInfoList = requestingInfo.getLoadingAdInfoList();

        if (biddingAttemptAdInfoList == null && loadingAdInfoList == null) {
            return new HashMap<>();
        }

        Map<String, Object> data = new HashMap<>();

        try {
            if (biddingAttemptAdInfoList != null && !biddingAttemptAdInfoList.isEmpty()) {
                List<Map<String, Object>> biddingAttemptList = new ArrayList<>();

                for (ATAdInfo atAdInfo : biddingAttemptAdInfoList) {
                    if (atAdInfo != null) {
                        biddingAttemptList.add(Utils.jsonStrToMap(atAdInfo.toString()));
                    }
                }

                data.put(Const.MultipleLoadedKeys.BiddingAttempt, biddingAttemptList);
            }
        } catch (Throwable e) {

        }

        try {
            if (loadingAdInfoList != null && !loadingAdInfoList.isEmpty()) {
                List<Map<String, Object>> loaddingList = new ArrayList<>();

                for (ATAdInfo atAdInfo : loadingAdInfoList) {
                    if (atAdInfo != null) {
                        loaddingList.add(Utils.jsonStrToMap(atAdInfo.toString()));
                    }
                }

                data.put(Const.MultipleLoadedKeys.Loading, loaddingList);
            }
        } catch (Throwable e) {

        }

        return data;
    }
}
