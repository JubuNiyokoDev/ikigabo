package com.ikigabo.ikigabo

import android.app.Activity
import android.view.View
import android.widget.FrameLayout
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
        private const val REWARDED_PLACEMENT_ID = "2120883338770182_2120906332101216"
        private const val BANNER_PLACEMENT_ID = "2120883338770182_2120903515434831"
    }

    private var interstitialAd: InterstitialAd? = null
    private var rewardedVideoAd: RewardedVideoAd? = null
    private var adView: AdView? = null

    fun handleMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "initialize" -> initialize(call, result)
            "loadInterstitial" -> loadInterstitial(result)
            "showInterstitial" -> showInterstitial(result)
            "loadRewarded" -> loadRewarded(result)
            "showRewarded" -> showRewarded(result)
            "loadBanner" -> loadBanner(call, result)
            "destroyBanner" -> destroyBanner(result)
            else -> result.notImplemented()
        }
    }

    private fun initialize(call: MethodCall, result: MethodChannel.Result) {
        AudienceNetworkAds.initialize(activity)
        val testDeviceId = call.argument<String>("testDeviceId")
        if (!testDeviceId.isNullOrEmpty()) {
            AdSettings.addTestDevice(testDeviceId)
        }
        result.success(true)
    }

    private fun loadInterstitial(result: MethodChannel.Result) {
        interstitialAd?.destroy()
        interstitialAd = InterstitialAd(activity, INTERSTITIAL_PLACEMENT_ID)

        val loadConfig = interstitialAd!!.buildLoadAdConfig()
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

        interstitialAd!!.loadAd(loadConfig)
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

    private fun loadRewarded(result: MethodChannel.Result) {
        rewardedVideoAd?.destroy()
        rewardedVideoAd = RewardedVideoAd(activity, REWARDED_PLACEMENT_ID)

        val loadConfig = rewardedVideoAd!!.buildLoadAdConfig()
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

        rewardedVideoAd!!.loadAd(loadConfig)
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

    private fun loadBanner(call: MethodCall, result: MethodChannel.Result) {
        adView?.destroy()
        adView = AdView(activity, BANNER_PLACEMENT_ID, AdSize.BANNER_HEIGHT_50)

        val loadConfig = adView!!.buildLoadAdConfig()
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

        adView!!.loadAd(loadConfig)
        result.success(true)
    }

    private fun destroyBanner(result: MethodChannel.Result) {
        adView?.destroy()
        adView = null
        result.success(true)
    }

    fun getBannerView(): View? = adView

    fun destroy() {
        interstitialAd?.destroy()
        interstitialAd = null
        rewardedVideoAd?.destroy()
        rewardedVideoAd = null
        adView?.destroy()
        adView = null
    }
}
