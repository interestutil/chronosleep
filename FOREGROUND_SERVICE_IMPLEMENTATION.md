# Foreground Service Implementation for Background Sensor Recording

## Summary

Implemented an Android foreground service to keep sensors running when the app is in the background. This ensures continuous light sensor data collection even when the user switches to other apps.

## Problem

Android and iOS pause sensor streams when apps go to the background to save battery. This caused lux readings to stop when the app was minimized, breaking continuous recording sessions.

## Solution

A foreground service keeps the app process alive and maintains sensor subscriptions, allowing continuous data collection in the background.

## Implementation

### 1. **Android Manifest Permissions** (`android/app/src/main/AndroidManifest.xml`)

Added required permissions:
- `FOREGROUND_SERVICE` - Required for foreground services (Android 14+)
- `FOREGROUND_SERVICE_DATA_SYNC` - Specific foreground service type for data collection
- `POST_NOTIFICATIONS` - Required to show notification (Android 13+)
- `WAKE_LOCK` - Keeps device CPU awake during recording

Registered the service:
```xml
<service
    android:name=".SensorRecordingService"
    android:enabled="true"
    android:exported="false"
    android:foregroundServiceType="dataSync" />
```

### 2. **Foreground Service Class** (`SensorRecordingService.kt`)

**Features**:
- **Persistent Notification**: Shows "Recording Sensor Data" notification (required for foreground services)
- **Wake Lock**: Prevents device from sleeping during recording (up to 10 hours)
- **Auto-restart**: Uses `START_STICKY` to restart if killed by system
- **Low Priority**: Notification is low priority to minimize user disruption

**Key Methods**:
- `onStartCommand()`: Handles START_RECORDING and STOP_RECORDING actions
- `createNotification()`: Creates persistent notification with tap-to-open
- `acquireWakeLock()`: Keeps device awake during recording
- `releaseWakeLock()`: Releases wake lock when service stops

### 3. **Platform Channel** (`MainActivity.kt`)

Added method channel to communicate between Flutter and Android:
- `startForegroundService`: Starts the foreground service
- `stopForegroundService`: Stops the foreground service

Uses `startForegroundService()` for Android 8.0+ (required for foreground services).

### 4. **Flutter Service Wrapper** (`lib/services/foreground_service.dart`)

Dart wrapper for the platform channel:
- `ForegroundService.start()`: Starts the service
- `ForegroundService.stop()`: Stops the service
- Handles errors gracefully with debug logging

### 5. **Recording Screen Integration** (`lib/ui/screens/recording_screen.dart`)

**Changes**:
- Starts foreground service when recording begins
- Stops foreground service when recording ends
- Updates sensor service state to prevent pausing when service is active

**Flow**:
1. User starts recording
2. Foreground service starts → shows notification
3. Sensors continue running even in background
4. User stops recording
5. Foreground service stops → notification removed

### 6. **Sensor Service Updates** (`lib/services/sensor_service.dart`)

**New Method**:
- `setForegroundServiceActive(bool)`: Tracks if foreground service is running

**Updated Logic**:
- `pause()`: Skips pausing if foreground service is active
- Sensors continue emitting samples when service is active, even in background

## How It Works

### Normal Flow

1. **User starts recording**:
   ```
   RecordingScreen._startRecording()
   → ForegroundService.start()
   → MainActivity.startForegroundService()
   → SensorRecordingService.onStartCommand(START_RECORDING)
   → Notification shown + Wake lock acquired
   → SensorService.setForegroundServiceActive(true)
   ```

2. **App goes to background**:
   ```
   RecordingScreen.didChangeAppLifecycleState(paused)
   → SensorService.pause()
   → Checks: _foregroundServiceActive == true
   → Skips pausing (sensors continue)
   ```

3. **User stops recording**:
   ```
   RecordingScreen._stopRecording()
   → ForegroundService.stop()
   → SensorRecordingService.onStartCommand(STOP_RECORDING)
   → Notification removed + Wake lock released
   → SensorService.setForegroundServiceActive(false)
   ```

### Benefits

1. **Continuous Recording**: Sensors work in background
2. **Battery Efficient**: Uses wake lock only during recording
3. **User Aware**: Notification shows recording is active
4. **System Compliant**: Follows Android foreground service requirements
5. **Auto-recovery**: Service restarts if killed by system

## Notification

The foreground service shows a persistent notification:
- **Title**: "Recording Sensor Data"
- **Text**: "Chronosleep is recording light exposure data"
- **Priority**: Low (minimal disruption)
- **Action**: Tap to return to app
- **Ongoing**: Cannot be dismissed (required for foreground service)

## Wake Lock

- **Type**: `PARTIAL_WAKE_LOCK` (keeps CPU awake, screen can sleep)
- **Duration**: Up to 10 hours (covers typical recording sessions)
- **Purpose**: Prevents device from sleeping and stopping sensors
- **Release**: Automatically released when service stops

## Platform Support

### Android
- ✅ **Fully Supported**: Foreground service keeps sensors active
- **Requirements**: Android 8.0+ (API 26+) for foreground services
- **Permissions**: Automatically requested on Android 13+ for notifications

### iOS
- ⚠️ **Limited Support**: iOS restricts background sensor access
- **Workaround**: Sensors may work briefly in background but will pause
- **Future**: Would require background modes (requires App Store justification)

## Testing

### To Verify It Works:

1. **Start Recording**:
   - Tap "Start Recording"
   - Verify notification appears
   - Check lux readings are updating

2. **Background Test**:
   - Press home button (app goes to background)
   - Wait 10-30 seconds
   - Check notification is still showing
   - Return to app
   - Verify lux readings continued (check timestamp)

3. **Stop Recording**:
   - Tap "Stop Recording"
   - Verify notification disappears
   - Verify sensors stop

### Troubleshooting

**Sensors still stop in background?**
- Check notification is showing (service is running)
- Check device battery optimization settings
- Some devices may still restrict sensors despite foreground service

**Notification not showing?**
- Android 13+: Check notification permission is granted
- Check device settings → Apps → Chronosleep → Notifications

**Battery drain?**
- Normal during recording (sensors + wake lock)
- Should stop when recording ends
- Check wake lock is released (notification disappears)

## Files Modified

1. `android/app/src/main/AndroidManifest.xml` - Permissions and service registration
2. `android/app/src/main/kotlin/.../SensorRecordingService.kt` - Foreground service implementation
3. `android/app/src/main/kotlin/.../MainActivity.kt` - Platform channel methods
4. `lib/services/foreground_service.dart` - Flutter service wrapper
5. `lib/services/sensor_service.dart` - Foreground service state tracking
6. `lib/ui/screens/recording_screen.dart` - Service start/stop integration

## Future Enhancements

1. **Custom Notification Icon**: Replace system icon with app icon
2. **Notification Actions**: Add pause/resume buttons in notification
3. **iOS Background Modes**: Implement iOS background modes (if approved)
4. **Battery Optimization**: Guide users to disable battery optimization
5. **Service Status**: Show service status in UI

## Conclusion

The foreground service implementation ensures sensors continue working in the background, enabling continuous circadian light exposure monitoring. The service is battery-efficient, user-friendly (with clear notification), and follows Android best practices.

