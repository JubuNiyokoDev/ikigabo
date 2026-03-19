package com.ikigabo.ikigabo

import android.app.AlarmManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
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

    override fun onCreate(savedInstanceState: Bundle?) {
        // Enable edge-to-edge - utiliser uniquement WindowCompat (compatible toutes versions)
        WindowCompat.setDecorFitsSystemWindows(window, false)
        super.onCreate(savedInstanceState)
        createNotificationChannel()
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

        val pendingIntent = buildAlarmPendingIntent(
            id = id,
            title = title,
            message = message,
            flags = PendingIntent.FLAG_UPDATE_CURRENT,
        ) ?: run {
            result.error("PENDING_INTENT_ERROR", "Impossible de créer PendingIntent", null)
            return
        }

        val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S && !alarmManager.canScheduleExactAlarms()) {
            alarmManager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, calendar.timeInMillis, pendingIntent)
        } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            alarmManager.setExactAndAllowWhileIdle(
                AlarmManager.RTC_WAKEUP,
                calendar.timeInMillis,
                pendingIntent,
            )
        } else {
            alarmManager.setExact(AlarmManager.RTC_WAKEUP, calendar.timeInMillis, pendingIntent)
        }

        result.success(true)
    }

    private fun cancelAlarm(call: MethodCall, result: MethodChannel.Result) {
        val id = call.argument<Int>("id")
        if (id == null) {
            result.error("INVALID_ARGS", "ID d'alarme manquant", null)
            return
        }

        val pendingIntent = buildAlarmPendingIntent(
            id = id,
            title = "",
            message = "",
            flags = PendingIntent.FLAG_NO_CREATE,
        )

        if (pendingIntent == null) {
            result.success(false)
            return
        }

        val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
        alarmManager.cancel(pendingIntent)
        pendingIntent.cancel()
        result.success(true)
    }

    private fun buildAlarmPendingIntent(
        id: Int,
        title: String,
        message: String,
        flags: Int,
    ): PendingIntent? {
        val intent = Intent(this, AlarmReceiver::class.java).apply {
            putExtra(EXTRA_ALARM_ID, id)
            putExtra(EXTRA_TITLE, title)
            putExtra(EXTRA_MESSAGE, message)
        }

        return PendingIntent.getBroadcast(
            this,
            id,
            intent,
            flags or pendingIntentMutabilityFlag(),
        )
    }

    private fun pendingIntentMutabilityFlag(): Int {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0
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
