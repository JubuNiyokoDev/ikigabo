package com.ikigabo.ikigabo

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.os.Build
import android.os.Bundle
import androidx.core.view.WindowCompat
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    companion object {
        const val CHANNEL = "real_alarm_channel"
        const val NOTIFICATION_CHANNEL_ID = "debt_reminders"
        const val EXTRA_ALARM_ID = "alarm_id"
        const val EXTRA_TITLE = "title"
        const val EXTRA_MESSAGE = "message"
    }

    private var metaAdsPlugin: MetaAdsPlugin? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        WindowCompat.setDecorFitsSystemWindows(window, false)
        super.onCreate(savedInstanceState)
        createNotificationChannel()
    }

    override fun onDestroy() {
        super.onDestroy()
        metaAdsPlugin?.destroy()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "setAlarm" -> scheduleAlarm(call, result)
                    "cancelAlarm" -> cancelAlarm(call, result)
                    "testService" -> result.success(true)
                    else -> result.notImplemented()
                }
            }

        val metaChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            MetaAdsPlugin.CHANNEL_NAME,
        )
        metaAdsPlugin = MetaAdsPlugin(this, metaChannel)
        metaChannel.setMethodCallHandler { call, result ->
            metaAdsPlugin!!.handleMethodCall(call, result)
        }

        flutterEngine.platformViewsController.registry
            .registerViewFactory("meta_banner_view", MetaBannerViewFactory(metaAdsPlugin!!))
        flutterEngine.platformViewsController.registry
            .registerViewFactory("meta_rectangle_view", MetaRectangleViewFactory(metaAdsPlugin!!))
    }

    private fun scheduleAlarm(call: MethodCall, result: MethodChannel.Result) {
        val id = call.argument<Int>("id")
        val hour = call.argument<Int>("hour")
        val minute = call.argument<Int>("minute")
        val day = call.argument<Int>("day")
        val month = call.argument<Int>("month")
        val year = call.argument<Int>("year")
        val title = call.argument<String>("title") ?: "Rappel"
        val message = call.argument<String>("message") ?: "Rappel de dette"

        if (id == null || hour == null || minute == null || day == null || month == null || year == null) {
            result.error("INVALID_ARGS", "Paramètres d'alarme invalides", null)
            return
        }

        val calendar = java.util.Calendar.getInstance().apply {
            set(java.util.Calendar.YEAR, year)
            set(java.util.Calendar.MONTH, month - 1)
            set(java.util.Calendar.DAY_OF_MONTH, day)
            set(java.util.Calendar.HOUR_OF_DAY, hour)
            set(java.util.Calendar.MINUTE, minute)
            set(java.util.Calendar.SECOND, 0)
            set(java.util.Calendar.MILLISECOND, 0)
        }

        if (calendar.timeInMillis <= System.currentTimeMillis()) {
            result.error("PAST_DATE", "Date d'alarme dans le passé", null)
            return
        }

        val scheduled = AlarmScheduler.scheduleAlarm(
            context = this,
            id = id,
            timeMillis = calendar.timeInMillis,
            title = title,
            message = message,
        )

        if (!scheduled) {
            result.error("SCHEDULE_ERROR", "Impossible de programmer l'alarme", null)
            return
        }

        result.success(true)
    }

    private fun cancelAlarm(call: MethodCall, result: MethodChannel.Result) {
        val id = call.argument<Int>("id")
        if (id == null) {
            result.error("INVALID_ARGS", "ID d'alarme manquant", null)
            return
        }

        result.success(AlarmScheduler.cancelAlarm(this, id))
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return

        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val existing = notificationManager.getNotificationChannel(NOTIFICATION_CHANNEL_ID)
        if (existing != null) return

        val channel = NotificationChannel(
            NOTIFICATION_CHANNEL_ID,
            "Rappels de Dettes",
            NotificationManager.IMPORTANCE_HIGH,
        ).apply {
            description = "Alarmes et rappels des dettes"
            enableVibration(true)
            setShowBadge(true)
        }

        notificationManager.createNotificationChannel(channel)
    }
}
