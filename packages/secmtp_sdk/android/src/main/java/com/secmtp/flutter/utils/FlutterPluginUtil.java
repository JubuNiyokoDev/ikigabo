package com.secmtp.flutter.utils;

import android.app.Activity;
import android.content.Context;
import android.os.Build;
import android.os.Handler;
import android.os.Looper;


public class FlutterPluginUtil {

    public static Activity sActivity;

    public static void setActivity(Activity activity) {
        sActivity = activity;
    }

    public static Activity getActivity() {
        return sActivity;
    }

    /** Non-null, not finishing, and not destroyed (API 17+). Safe for UI / SDK show. */
    public static boolean isActivityUsable(Activity activity) {
        if (activity == null) {
            return false;
        }
        if (activity.isFinishing()) {
            return false;
        }
        return Build.VERSION.SDK_INT < Build.VERSION_CODES.JELLY_BEAN_MR1 || !activity.isDestroyed();
    }

    public static Context getApplicationContext() {
        try {
            return sActivity.getApplicationContext();
        } catch (Throwable e) {
            e.printStackTrace();
        }
        return null;
    }

    public static void runOnUiThread(final Runnable runnable) {
        try {
            if (Looper.getMainLooper() == Looper.myLooper()) {
                runnable.run();
            } else {
                Activity a = getActivity();
                if (a != null) {
                    a.runOnUiThread(runnable);
                } else {
                    new Handler(Looper.getMainLooper()).post(runnable);
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

}
