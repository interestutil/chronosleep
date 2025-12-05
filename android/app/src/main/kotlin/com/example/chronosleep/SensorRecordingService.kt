package com.example.chronosleep

import android.app.*
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import android.os.PowerManager
import android.util.Log
import androidx.core.app.NotificationCompat

class SensorRecordingService : Service() {
    private var wakeLock: PowerManager.WakeLock? = null
    private val CHANNEL_ID = "sensor_recording_channel"
    private val NOTIFICATION_ID = 1
    private val TAG = "SensorRecordingService"

    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "Service onCreate()")
        createNotificationChannel()
        acquireWakeLock()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d(TAG, "onStartCommand() called with action: ${intent?.action}")
        
        when (intent?.action) {
            "START_RECORDING" -> {
                Log.d(TAG, "Starting foreground service")
                try {
                    startForeground(NOTIFICATION_ID, createNotification())
                    Log.d(TAG, "Foreground service started successfully")
                } catch (e: Exception) {
                    Log.e(TAG, "Error starting foreground service: ${e.message}", e)
                }
            }
            "STOP_RECORDING" -> {
                Log.d(TAG, "Stopping foreground service")
                stopForeground(STOP_FOREGROUND_REMOVE)
                stopSelf()
            }
            else -> {
                // If no action specified, start as foreground anyway
                Log.d(TAG, "No action specified, starting as foreground")
                try {
                    startForeground(NOTIFICATION_ID, createNotification())
                } catch (e: Exception) {
                    Log.e(TAG, "Error starting foreground service: ${e.message}", e)
                }
            }
        }
        return START_STICKY // Restart if killed by system
    }

    override fun onBind(intent: Intent?): IBinder? {
        return null
    }

    override fun onDestroy() {
        super.onDestroy()
        releaseWakeLock()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            try {
                val channel = NotificationChannel(
                    CHANNEL_ID,
                    "Sensor Recording",
                    NotificationManager.IMPORTANCE_LOW
                ).apply {
                    description = "Recording sensor data for circadian analysis"
                    setShowBadge(false)
                }
                val notificationManager = getSystemService(NotificationManager::class.java)
                notificationManager.createNotificationChannel(channel)
                Log.d(TAG, "Notification channel created")
            } catch (e: Exception) {
                Log.e(TAG, "Error creating notification channel: ${e.message}", e)
            }
        }
    }

    private fun createNotification(): Notification {
        val intent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
        }
        val pendingIntent = PendingIntent.getActivity(
            this, 0, intent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Recording Sensor Data")
            .setContentText("Chronosleep is recording light exposure data")
            .setSmallIcon(android.R.drawable.ic_dialog_info) // Using system icon for now
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .build()
    }

    private fun acquireWakeLock() {
        try {
            val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
            wakeLock = powerManager.newWakeLock(
                PowerManager.PARTIAL_WAKE_LOCK,
                "Chronosleep::SensorRecordingWakeLock"
            ).apply {
                acquire(10 * 60 * 60 * 1000L /*10 hours*/) // Max 10 hours
            }
            Log.d(TAG, "Wake lock acquired")
        } catch (e: Exception) {
            Log.e(TAG, "Error acquiring wake lock: ${e.message}", e)
        }
    }

    private fun releaseWakeLock() {
        try {
            wakeLock?.let {
                if (it.isHeld) {
                    it.release()
                    Log.d(TAG, "Wake lock released")
                }
            }
            wakeLock = null
        } catch (e: Exception) {
            Log.e(TAG, "Error releasing wake lock: ${e.message}", e)
        }
    }
}

