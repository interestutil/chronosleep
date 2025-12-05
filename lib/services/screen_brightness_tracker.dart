// lib/services/screen_brightness_tracker.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'sensor_service.dart';

/// Tracks screen brightness and state, updating SensorService when changes occur
class ScreenBrightnessTracker {
  final SensorService sensorService;
  final ScreenBrightness _screenBrightness = ScreenBrightness();
  
  Timer? _brightnessCheckTimer;
  double? _lastBrightness;
  bool _isTracking = false;

  ScreenBrightnessTracker({required this.sensorService});

  /// Start tracking screen brightness
  Future<void> start() async {
    if (_isTracking) return;
    _isTracking = true;

    // Get initial brightness
    await _updateBrightness();

    // Set up periodic brightness checks (every 2 seconds)
    // This catches both brightness changes and screen on/off events
    _brightnessCheckTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => _updateBrightness(),
    );
  }

  /// Stop tracking screen brightness
  void stop() {
    _isTracking = false;
    _brightnessCheckTimer?.cancel();
    _brightnessCheckTimer = null;
  }

  /// Update brightness from system and notify SensorService
  Future<void> _updateBrightness() async {
    if (!_isTracking) return;
    
    try {
      final brightness = await _screenBrightness.system;
      
      // Check if brightness changed significantly (>5% change) or is first reading
      if (_lastBrightness == null || 
          (brightness - _lastBrightness!).abs() > 0.05) {
        _lastBrightness = brightness;
        
        // Update sensor service with screen state
        // Screen is considered "on" if brightness > 0.01 (1%)
        final screenOn = brightness > 0.01;
        sensorService.updateScreenState(
          on: screenOn,
          brightness: screenOn ? brightness : null,
        );
        
        if (kDebugMode) {
          debugPrint('ScreenBrightnessTracker: Screen ${screenOn ? "on" : "off"}, '
              'brightness: ${(brightness * 100).toStringAsFixed(1)}%');
        }
      }
    } catch (e) {
      // Screen brightness may not be available on all devices
      // On some devices, reading brightness might fail when screen is off
      // Try to detect screen off by catching the error
      if (kDebugMode) {
        debugPrint('ScreenBrightnessTracker: Error reading brightness: $e');
      }
      
      // If we previously had a brightness reading and now we can't read it,
      // the screen might be off
      if (_lastBrightness != null && _lastBrightness! > 0.01) {
        // Screen might have turned off
        _lastBrightness = 0.0;
        sensorService.updateScreenState(on: false, brightness: null);
        if (kDebugMode) {
          debugPrint('ScreenBrightnessTracker: Screen appears to be off');
        }
      } else {
        // First read or already off - default to screen on with unknown brightness
        sensorService.updateScreenState(on: true, brightness: null);
      }
    }
  }

  /// Manually update screen state (for app lifecycle changes)
  void updateScreenState(bool screenOn) {
    if (screenOn && _lastBrightness != null && _lastBrightness! > 0.01) {
      sensorService.updateScreenState(
        on: true,
        brightness: _lastBrightness,
      );
    } else {
      sensorService.updateScreenState(
        on: false,
        brightness: null,
      );
    }
  }

  void dispose() {
    stop();
  }
}

