package com.secmtp.flutter.utils;

import android.app.Activity;
import android.content.Context;
import android.view.View;
import android.view.ViewParent;
import android.view.Window;
import android.view.inputmethod.InputMethodManager;

/**
 * Native ad {@link io.flutter.plugin.platform.PlatformView} only (not banner).
 * When disposed, release IME/focus held by embedded ad views so Flutter
 * {@code TextField} can attach input again.
 */
public final class PlatformViewImeHelper {

    private PlatformViewImeHelper() {
    }

    public static void clearFocusAndHideIme(View root) {
        if (root == null) {
            return;
        }
        try {
            Context ctx = root.getContext();
            if (ctx == null) {
                return;
            }
            InputMethodManager imm =
                    (InputMethodManager) ctx.getSystemService(Context.INPUT_METHOD_SERVICE);
            if (imm != null) {
                imm.hideSoftInputFromWindow(root.getWindowToken(), 0);
            }
            Activity activity = findActivity(ctx);
            if (activity != null) {
                View current = activity.getCurrentFocus();
                if (isDescendantOf(root, current)) {
                    current.clearFocus();
                }
                Window window = activity.getWindow();
                if (window != null) {
                    window.getDecorView().clearFocus();
                }
            }
            root.clearFocus();
        } catch (Throwable ignored) {
        }
    }

    private static Activity findActivity(Context context) {
        Context c = context;
        int depth = 0;
        while (c != null && depth++ < 16) {
            if (c instanceof Activity) {
                return (Activity) c;
            }
            if (c instanceof android.content.ContextWrapper) {
                c = ((android.content.ContextWrapper) c).getBaseContext();
            } else {
                return null;
            }
        }
        return null;
    }

    private static boolean isDescendantOf(View ancestor, View descendant) {
        if (descendant == null || ancestor == null) {
            return false;
        }
        View v = descendant;
        int depth = 0;
        while (v != null && depth++ < 64) {
            if (v == ancestor) {
                return true;
            }
            ViewParent p = v.getParent();
            v = (p instanceof View) ? (View) p : null;
        }
        return false;
    }
}
