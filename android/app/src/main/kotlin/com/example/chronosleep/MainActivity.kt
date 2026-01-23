package com.example.chronosleep

import android.content.Intent
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.chronosleep/foreground_service"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startForegroundService" -> {
                    try {
                        val intent = Intent(this, SensorRecordingService::class.java)
                        intent.action = "START_RECORDING"
                        
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            startForegroundService(intent)
                        } else {
                            startService(intent)
                        }
                        
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("SERVICE_ERROR", "Failed to start foreground service: ${e.message}", null)
                    }
                }
                "stopForegroundService" -> {
                    try {
                        val intent = Intent(this, SensorRecordingService::class.java)
                        intent.action = "STOP_RECORDING"
                        startService(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("SERVICE_ERROR", "Failed to stop foreground service: ${e.message}", null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
}
