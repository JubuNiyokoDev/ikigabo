package com.ikigabo.ikigabo

import android.app.Activity
import android.view.View
import com.facebook.ads.*
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class MetaAdsPlugin(
    private val activity: Activity,
    private val channel: MethodChannel,
) {
    companion object {
        const val CHANNEL_NAME = "meta_ads_channel"
        private const val INTERSTITIAL_PLACEMENT_ID = "2120883338770182_2120901345435048"
        private const val REWARDED_PLACEMENT_ID    = "2120883338770182_2120906332101216"
        private const val BANNER_PLACEMENT_ID      = "2120883338770182_2120903515434831"
        private const val RECTANGLE_PLACEMENT_ID   = "2120883338770182_2120904505434732"
    }

    private var interstitialAd: InterstitialAd? = null
    private var rewardedVideoAd: RewardedVideoAd? = null
    private var bannerView: AdView? = null
    private var rectangleView: AdView? = null

    fun handleMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "initialize"      -> initialize(call, result)
            "loadInterstitial" -> loadInterstitial(result)
            "showInterstitial" -> showInterstitial(result)
            "loadRewarded"    -> loadRewarded(result)
            "showRewarded"    -> showRewarded(result)
            "loadBanner"      -> loadBanner(result)
            "destroyBanner"   -> destroyBanner(result)
            "loadRectangle"   -> loadRectangle(result)
            "destroyRectangle" -> destroyRectangle(result)
            else -> result.notImplemented()
        }
    }

    // ── Init (async — attend la fin avant de répondre à Flutter) ─────────────
    private fun initialize(call: MethodCall, result: MethodChannel.Result) {
        val testDeviceId = call.argument<String>("testDeviceId")
        if (!testDeviceId.isNullOrEmpty()) {
            AdSettings.addTestDevice(testDeviceId)
        }
        AudienceNetworkAds
            .buildInitSettings(activity)
            .withInitListener { initResult ->
                activity.runOnUiThread {
                    result.success(initResult.isSuccess)
                }
            }
            .initialize()
    }

    // ── Interstitial ─────────────────────────────────────────────────────────
    private fun loadInterstitial(result: MethodChannel.Result) {
        interstitialAd?.destroy()
        interstitialAd = InterstitialAd(activity, INTERSTITIAL_PLACEMENT_ID)
        interstitialAd!!.loadAd(
            interstitialAd!!.buildLoadAdConfig()
                .withAdListener(object : InterstitialAdListener {
                    override fun onInterstitialDisplayed(ad: Ad?) {}
                    override fun onInterstitialDismissed(ad: Ad?) {
                        activity.runOnUiThread {
                            channel.invokeMethod("onInterstitialDismissed", null)
                        }
                    }
                    override fun onError(ad: Ad?, adError: AdError?) {
                        activity.runOnUiThread {
                            channel.invokeMethod("onInterstitialLoadFailed", adError?.errorMessage)
                        }
                    }
                    override fun onAdLoaded(ad: Ad?) {
                        activity.runOnUiThread {
                            channel.invokeMethod("onInterstitialLoaded", null)
                        }
                    }
                    override fun onAdClicked(ad: Ad?) {}
                    override fun onLoggingImpression(ad: Ad?) {}
                })
                .build()
        )
        result.success(true)
    }

    private fun showInterstitial(result: MethodChannel.Result) {
        val ad = interstitialAd
        if (ad != null && ad.isAdLoaded && !ad.isAdInvalidated) {
            ad.show()
            result.success(true)
        } else {
            result.success(false)
        }
    }

    // ── Rewarded ─────────────────────────────────────────────────────────────
    private fun loadRewarded(result: MethodChannel.Result) {
        rewardedVideoAd?.destroy()
        rewardedVideoAd = RewardedVideoAd(activity, REWARDED_PLACEMENT_ID)
        rewardedVideoAd!!.loadAd(
            rewardedVideoAd!!.buildLoadAdConfig()
                .withAdListener(object : RewardedVideoAdListener {
                    override fun onRewardedVideoCompleted() {
                        activity.runOnUiThread {
                            channel.invokeMethod("onRewardedComplete", null)
                        }
                    }
                    override fun onLoggingImpression(ad: Ad?) {}
                    override fun onRewardedVideoClosed() {
                        activity.runOnUiThread {
                            channel.invokeMethod("onRewardedClosed", null)
                        }
                    }
                    override fun onError(ad: Ad?, adError: AdError?) {
                        activity.runOnUiThread {
                            channel.invokeMethod("onRewardedLoadFailed", adError?.errorMessage)
                        }
                    }
                    override fun onAdLoaded(ad: Ad?) {
                        activity.runOnUiThread {
                            channel.invokeMethod("onRewardedLoaded", null)
                        }
                    }
                    override fun onAdClicked(ad: Ad?) {}
                })
                .build()
        )
        result.success(true)
    }

    private fun showRewarded(result: MethodChannel.Result) {
        val ad = rewardedVideoAd
        if (ad != null && ad.isAdLoaded && !ad.isAdInvalidated) {
            ad.show()
            result.success(true)
        } else {
            result.success(false)
        }
    }

    // ── Banner (320x50) ──────────────────────────────────────────────────────
    private fun loadBanner(result: MethodChannel.Result) {
        bannerView?.destroy()
        bannerView = AdView(activity, BANNER_PLACEMENT_ID, AdSize.BANNER_HEIGHT_50)
        bannerView!!.loadAd(
            bannerView!!.buildLoadAdConfig()
                .withAdListener(object : AdListener {
                    override fun onError(ad: Ad?, adError: AdError?) {
                        activity.runOnUiThread {
                            channel.invokeMethod("onBannerLoadFailed", adError?.errorMessage)
                        }
                    }
                    override fun onAdLoaded(ad: Ad?) {
                        activity.runOnUiThread {
                            channel.invokeMethod("onBannerLoaded", null)
                        }
                    }
                    override fun onAdClicked(ad: Ad?) {}
                    override fun onLoggingImpression(ad: Ad?) {}
                })
                .build()
        )
        result.success(true)
    }

    private fun destroyBanner(result: MethodChannel.Result) {
        bannerView?.destroy()
        bannerView = null
        result.success(true)
    }

    // ── Rectangle (300x250) ──────────────────────────────────────────────────
    private fun loadRectangle(result: MethodChannel.Result) {
        rectangleView?.destroy()
        rectangleView = AdView(activity, RECTANGLE_PLACEMENT_ID, AdSize.RECTANGLE_HEIGHT_250)
        rectangleView!!.loadAd(
            rectangleView!!.buildLoadAdConfig()
                .withAdListener(object : AdListener {
                    override fun onError(ad: Ad?, adError: AdError?) {
                        activity.runOnUiThread {
                            channel.invokeMethod("onRectangleLoadFailed", adError?.errorMessage)
                        }
                    }
                    override fun onAdLoaded(ad: Ad?) {
                        activity.runOnUiThread {
                            channel.invokeMethod("onRectangleLoaded", null)
                        }
                    }
                    override fun onAdClicked(ad: Ad?) {}
                    override fun onLoggingImpression(ad: Ad?) {}
                })
                .build()
        )
        result.success(true)
    }

    private fun destroyRectangle(result: MethodChannel.Result) {
        rectangleView?.destroy()
        rectangleView = null
        result.success(true)
    }

    // ── Getters pour les PlatformViews ───────────────────────────────────────
    fun getBannerView(): android.view.View? = bannerView
    fun getRectangleView(): android.view.View? = rectangleView

    fun destroy() {
        interstitialAd?.destroy()
        interstitialAd = null
        rewardedVideoAd?.destroy()
        rewardedVideoAd = null
        bannerView?.destroy()
        bannerView = null
        rectangleView?.destroy()
        rectangleView = null
    }
}
