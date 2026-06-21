package com.sopstudio.bodycurrent

import android.content.Intent
import android.content.IntentFilter
import android.os.BatteryManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "com.sopstudio.bodycurrent/battery"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                if (call.method == "getVoltageMv") {
                    val intent = applicationContext.registerReceiver(
                        null,
                        IntentFilter(Intent.ACTION_BATTERY_CHANGED),
                    )
                    val voltage = intent?.getIntExtra(BatteryManager.EXTRA_VOLTAGE, -1) ?: -1
                    if (voltage > 0) {
                        result.success(voltage)
                    } else {
                        result.success(null)
                    }
                } else {
                    result.notImplemented()
                }
            }
    }
}
