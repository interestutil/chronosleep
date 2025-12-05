package com.example.chronosleep

import android.content.Intent
import android.os.Build
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.chronosleep/foreground_service"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startForegroundService" -> {
                    try {
                        android.util.Log.d("MainActivity", "Starting foreground service...")
                        val intent = Intent(this, SensorRecordingService::class.java).apply {
                            action = "START_RECORDING"
                        }
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            android.util.Log.d("MainActivity", "Calling startForegroundService()")
                            startForegroundService(intent)
                        } else {
                            android.util.Log.d("MainActivity", "Calling startService()")
                            startService(intent)
                        }
                        android.util.Log.d("MainActivity", "Service start command sent")
                        result.success(true)
                    } catch (e: Exception) {
                        android.util.Log.e("MainActivity", "Error starting service: ${e.message}", e)
                        result.error("SERVICE_ERROR", "Failed to start service: ${e.message}", null)
                    }
                }
                "stopForegroundService" -> {
                    try {
                        val intent = Intent(this, SensorRecordingService::class.java).apply {
                            action = "STOP_RECORDING"
                        }
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            startForegroundService(intent)
                        } else {
                            startService(intent)
                        }
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("SERVICE_ERROR", "Failed to stop service: ${e.message}", null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
}
