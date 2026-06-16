package com.ikigabo.ikigabo

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import org.json.JSONArray
import org.json.JSONObject

object AlarmScheduler {
    private const val PREFS_NAME = "ikigabo_alarm_store"
    private const val KEY_ALARMS = "alarms"

    fun scheduleAlarm(
        context: Context,
        id: Int,
        timeMillis: Long,
        title: String,
        message: String,
        persist: Boolean = true,
    ): Boolean {
        if (timeMillis <= System.currentTimeMillis()) return false

        val pendingIntent = buildAlarmPendingIntent(
            context = context,
            id = id,
            title = title,
            message = message,
            flags = PendingIntent.FLAG_UPDATE_CURRENT,
        ) ?: return false

        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S && !alarmManager.canScheduleExactAlarms()) {
            alarmManager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, timeMillis, pendingIntent)
        } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            alarmManager.setExactAndAllowWhileIdle(
                AlarmManager.RTC_WAKEUP,
                timeMillis,
                pendingIntent,
            )
        } else {
            alarmManager.setExact(AlarmManager.RTC_WAKEUP, timeMillis, pendingIntent)
        }

        if (persist) {
            saveAlarm(context, SavedAlarm(id, timeMillis, title, message))
        }

        return true
    }

    fun cancelAlarm(context: Context, id: Int): Boolean {
        val pendingIntent = buildAlarmPendingIntent(
            context = context,
            id = id,
            title = "",
            message = "",
            flags = PendingIntent.FLAG_NO_CREATE,
        )

        if (pendingIntent != null) {
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            alarmManager.cancel(pendingIntent)
            pendingIntent.cancel()
        }

        removeSavedAlarm(context, id)
        return pendingIntent != null
    }

    fun removeSavedAlarm(context: Context, id: Int) {
        val alarms = loadAlarms(context).filterNot { it.id == id }
        writeAlarms(context, alarms)
    }

    fun rescheduleSavedAlarms(context: Context) {
        val now = System.currentTimeMillis()
        val activeAlarms = mutableListOf<SavedAlarm>()

        for (alarm in loadAlarms(context)) {
            if (alarm.timeMillis <= now) continue

            val scheduled = scheduleAlarm(
                context = context,
                id = alarm.id,
                timeMillis = alarm.timeMillis,
                title = alarm.title,
                message = alarm.message,
                persist = false,
            )

            if (scheduled) {
                activeAlarms.add(alarm)
            }
        }

        writeAlarms(context, activeAlarms)
    }

    private fun saveAlarm(context: Context, alarm: SavedAlarm) {
        val alarms = loadAlarms(context)
            .filterNot { it.id == alarm.id }
            .toMutableList()
            .apply { add(alarm) }

        writeAlarms(context, alarms)
    }

    private fun loadAlarms(context: Context): List<SavedAlarm> {
        val raw = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            .getString(KEY_ALARMS, "[]")

        val alarms = mutableListOf<SavedAlarm>()
        val jsonArray = try {
            JSONArray(raw ?: "[]")
        } catch (_: Exception) {
            JSONArray()
        }

        for (index in 0 until jsonArray.length()) {
            val json = jsonArray.optJSONObject(index) ?: continue
            val id = json.optInt("id", -1)
            val timeMillis = json.optLong("timeMillis", 0L)
            val title = json.optString("title", "Rappel")
            val message = json.optString("message", "Ikigabo")

            if (id >= 0 && timeMillis > 0L) {
                alarms.add(SavedAlarm(id, timeMillis, title, message))
            }
        }

        return alarms
    }

    private fun writeAlarms(context: Context, alarms: List<SavedAlarm>) {
        val jsonArray = JSONArray()
        alarms.forEach { alarm ->
            jsonArray.put(
                JSONObject()
                    .put("id", alarm.id)
                    .put("timeMillis", alarm.timeMillis)
                    .put("title", alarm.title)
                    .put("message", alarm.message),
            )
        }

        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            .edit()
            .putString(KEY_ALARMS, jsonArray.toString())
            .apply()
    }

    private fun buildAlarmPendingIntent(
        context: Context,
        id: Int,
        title: String,
        message: String,
        flags: Int,
    ): PendingIntent? {
        val intent = Intent(context, AlarmReceiver::class.java).apply {
            putExtra(MainActivity.EXTRA_ALARM_ID, id)
            putExtra(MainActivity.EXTRA_TITLE, title)
            putExtra(MainActivity.EXTRA_MESSAGE, message)
        }

        return PendingIntent.getBroadcast(
            context,
            id,
            intent,
            flags or pendingIntentMutabilityFlag(),
        )
    }

    private fun pendingIntentMutabilityFlag(): Int {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0
    }

    private data class SavedAlarm(
        val id: Int,
        val timeMillis: Long,
        val title: String,
        val message: String,
    )
}
