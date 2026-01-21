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
  /// This method continues to work in background if foreground service is active
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
      // On some devices, reading brightness might fail when screen is off or app is in background
      // Don't immediately assume screen is off - keep last known state
      if (kDebugMode) {
        debugPrint('ScreenBrightnessTracker: Error reading brightness: $e');
        debugPrint('ScreenBrightnessTracker: Keeping last known brightness state');
      }
      
      // If we have a last known brightness, keep using it
      // This ensures continuous monitoring even when brightness can't be read
      if (_lastBrightness != null && _lastBrightness! > 0.01) {
        // Keep using the last known brightness value
        // This ensures monitoring continues even when brightness API fails
        // The screen is likely still on, we just can't read it right now (e.g., app in background)
        final screenOn = true; // Assume screen is still on if we had a reading
        sensorService.updateScreenState(
          on: screenOn,
          brightness: _lastBrightness, // Use last known brightness
        );
        if (kDebugMode) {
          debugPrint('ScreenBrightnessTracker: Using last known brightness: ${(_lastBrightness! * 100).toStringAsFixed(1)}% (brightness read failed)');
        }
      } else if (_lastBrightness == null) {
        // First read failed - assume screen is on with unknown brightness
        // This is safer than assuming it's off
        sensorService.updateScreenState(on: true, brightness: null);
        if (kDebugMode) {
          debugPrint('ScreenBrightnessTracker: First read failed - assuming screen on');
        }
      } else {
        // _lastBrightness is 0 or very low - screen is likely off
        // Keep this state but still emit a sample
        sensorService.updateScreenState(on: false, brightness: null);
        if (kDebugMode) {
          debugPrint('ScreenBrightnessTracker: Screen appears off (last brightness was 0)');
        }
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

