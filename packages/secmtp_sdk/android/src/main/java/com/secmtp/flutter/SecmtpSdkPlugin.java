package com.secmtp.flutter;

import androidx.annotation.NonNull;

import com.secmtp.flutter.utils.FlutterPluginUtil;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;

/**
 * SdkPlugin
 */
public class SecmtpSdkPlugin implements FlutterPlugin, ActivityAware {

    private FlutterPlugin.FlutterPluginBinding pluginBinding;

    /**
     * <p>Channel recovery: When relying on Activity attach or configuration changes for re-attach</p>
     * <p>Perform defensive initialization using the saved {@link FlutterPlugin.FlutterPluginBinding} with the method {@link ATFlutterEventManager#init};</p>
     * <p>Use {@link ATFlutterEventManager#releaseForMessenger} in {@link #onDetachedFromEngine} to avoid multiple Engines mistakenly clearing the main channel.</p>
     */
    @Override
    public void onAttachedToEngine(@NonNull FlutterPlugin.FlutterPluginBinding flutterPluginBinding) {
        this.pluginBinding = flutterPluginBinding;
        // Platform views are registered per engine. The method channel is
        // activated only when this engine owns an Activity, so a headless
        // Firebase Messaging engine cannot replace the app's TopOn channel.
        ATPlatformViewManager.getInstance().init(flutterPluginBinding);
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPlugin.FlutterPluginBinding binding) {
        //release
        ATFlutterEventManager.getInstance().releaseForMessenger(binding.getBinaryMessenger());
        this.pluginBinding = null;
    }

    @Override
    public void onAttachedToActivity(@NonNull ActivityPluginBinding activityPluginBinding) {
        FlutterPluginUtil.setActivity(activityPluginBinding.getActivity());
        ensureMethodChannelIfNeeded();
    }

    @Override
    public void onDetachedFromActivityForConfigChanges() {

    }

    @Override
    public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding activityPluginBinding) {
        FlutterPluginUtil.setActivity(activityPluginBinding.getActivity());
        ensureMethodChannelIfNeeded();
    }

    @Override
    public void onDetachedFromActivity() {

    }

    /**
     * If the channel has been released and there is still a messenger bound to the engine, then re-initialize it.
     */
    private void ensureMethodChannelIfNeeded() {
        if (pluginBinding != null) {
            ATFlutterEventManager.getInstance().init(pluginBinding.getBinaryMessenger());
        }
    }
}
