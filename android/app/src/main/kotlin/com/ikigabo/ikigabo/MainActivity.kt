package com.ikigabo.ikigabo

import android.content.Intent
import android.os.Bundle
import android.provider.AlarmClock
import androidx.core.view.WindowCompat
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    private val CHANNEL = "real_alarm_channel"

    override fun onCreate(savedInstanceState: Bundle?) {
        // Enable edge-to-edge - utiliser uniquement WindowCompat (compatible toutes versions)
        WindowCompat.setDecorFitsSystemWindows(window, false)
        super.onCreate(savedInstanceState)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "setAlarm" -> {
                    val hour = call.argument<Int>("hour") ?: 0
                    val minute = call.argument<Int>("minute") ?: 0
                    val message = call.argument<String>("message") ?: "Rappel Dette"
                    
                    setSystemAlarm(hour, minute, message)
                    result.success("Alarme programmée")
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun setSystemAlarm(hour: Int, minute: Int, message: String) {
        val intent = Intent(AlarmClock.ACTION_SET_ALARM).apply {
            putExtra(AlarmClock.EXTRA_HOUR, hour)
            putExtra(AlarmClock.EXTRA_MINUTES, minute)
            putExtra(AlarmClock.EXTRA_MESSAGE, message)
            putExtra(AlarmClock.EXTRA_SKIP_UI, false)
        }
        
        if (intent.resolveActivity(packageManager) != null) {
            startActivity(intent)
        }
    }
}
