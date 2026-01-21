// lib/services/sensor_service.dart
import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:light/light.dart';
import '../models/light_sample.dart';
import '../utils/constants.dart';

class SensorService {
  // Singletons or instance via provider
  final _lightPlugin = Light();
  StreamSubscription<dynamic>? _luxSubscription;
  StreamSubscription<AccelerometerEvent>? _accelSub;

  final StreamController<LightSample> _sampleController =
      StreamController.broadcast();
  Stream<LightSample> get sampleStream => _sampleController.stream;

  double? _lastAmbientLux;
  double? _smoothedLux; // Exponential moving average
  double _lastAccelMag = 0.0;
  double? _lastPitch; // Device pitch angle in radians (for viewing angle calculation)
  bool _screenOn = true;
  double? _screenBrightness; // read via platform channel
  bool _isPaused = false;
  bool _isStarted = false;
  bool _foregroundServiceActive = false;

  /// start sensors
  Future<void> start() async {
    if (_isStarted && !_isPaused) {
      // Already started and not paused
      return;
    }
    
    _isStarted = true;
    _isPaused = false;
    
    // Reset smoothing when starting new recording (only if not resuming)
    if (!_isStarted || _luxSubscription == null) {
      _smoothedLux = null;
    }
    
    // Subscribe to sensors
    await _subscribeToSensors();
  }

  /// Set foreground service state
  /// When foreground service is active, sensors should continue even in background
  void setForegroundServiceActive(bool active) {
    _foregroundServiceActive = active;
    if (kDebugMode) {
      debugPrint('SensorService: Foreground service ${active ? "active" : "inactive"}');
    }
  }

  /// Pause sensors (when app goes to background)
  /// Note: If foreground service is active, we don't pause - sensors should continue
  Future<void> pause() async {
    if (!_isStarted || _isPaused) return;
    
    // Don't pause if foreground service is keeping us alive
    if (_foregroundServiceActive) {
      if (kDebugMode) {
        debugPrint('SensorService: App in background but foreground service active - sensors continue');
      }
      return;
    }
    
    _isPaused = true;
    
    if (kDebugMode) {
      debugPrint('SensorService: App in background (sensors may continue if OS allows)');
    }
    
    // Don't cancel subscriptions - let them continue if OS allows
    // This allows sensors to keep working in background on some platforms
  }

  /// Resume sensors (when app comes to foreground)
  /// Checks if sensors are still active and restarts if needed
  Future<void> resume() async {
    if (!_isStarted || !_isPaused) return;
    _isPaused = false;
    
    if (kDebugMode) {
      debugPrint('SensorService: App in foreground - checking sensor status');
    }
    
    // Check if subscriptions are still active
    // If not, restart them
    if (_luxSubscription == null || _accelSub == null) {
      if (kDebugMode) {
        debugPrint('SensorService: Sensors stopped - restarting');
      }
      // Restart sensors - but don't reset smoothing state
      await _subscribeToSensors();
    } else {
      // Sensors appear active - emit a sample to verify
      // If no events come through, we'll detect it and restart
      _emitSample();
      
      // Set up a check: if no lux events come within 2 seconds, restart
      Future.delayed(const Duration(seconds: 2), () {
        if (_isStarted && !_isPaused && _lastAmbientLux == null) {
          if (kDebugMode) {
            debugPrint('SensorService: No events detected after resume - restarting sensors');
          }
          _subscribeToSensors();
        }
      });
    }
  }
  
  /// Internal method to subscribe to sensors
  Future<void> _subscribeToSensors() async {
    // Subscribe to ambient light (Android)
    try {
      // Cancel existing subscription if any
      await _luxSubscription?.cancel();
      
      _luxSubscription =
          _lightPlugin.lightSensorStream.listen((dynamic luxVal) {
        if (luxVal is num) {
          final rawLux = luxVal.toDouble();
          
          // Validate reading: check for NaN, infinity, and range
          if (!rawLux.isFinite || rawLux.isNaN) {
            if (kDebugMode) {
              debugPrint('SensorService: Invalid lux reading (NaN/Inf): $rawLux');
            }
            return; // Skip invalid reading
          }
          
          // Clamp to valid range
          final clampedLux = CircadianMath.clamp(
            rawLux,
            CircadianConstants.minValidLux,
            CircadianConstants.maxValidLux,
          );
          
          if (rawLux != clampedLux && kDebugMode) {
            debugPrint('SensorService: Lux value $rawLux clamped to $clampedLux');
          }
          
          // Apply dead-band filter: ignore very small changes
          double luxToProcess = clampedLux;
          if (_smoothedLux != null) {
            final change = (clampedLux - _smoothedLux!).abs();
            if (change < CircadianConstants.deadBandLux) {
              // Change is too small, keep current smoothed value
              luxToProcess = _smoothedLux!;
            }
          }
          
          // Outlier detection: check for sudden large changes
          if (_smoothedLux != null && _smoothedLux! > 0) {
            final percentChange = (luxToProcess - _smoothedLux!).abs() / 
                                 (_smoothedLux! + 1.0); // +1 to avoid division by zero
            if (percentChange > CircadianConstants.outlierThresholdPercent) {
              if (kDebugMode) {
                debugPrint('SensorService: Possible outlier detected: '
                    '$luxToProcess (${(percentChange * 100).toStringAsFixed(1)}% change from ${_smoothedLux!.toStringAsFixed(1)})');
              }
              // For outliers, use weighted average instead of full EMA
              // This reduces impact of outliers while still allowing large real changes
              luxToProcess = 0.3 * luxToProcess + 0.7 * _smoothedLux!;
            }
          }
          
          _lastAmbientLux = clampedLux; // Store clamped value
          
          // Apply exponential moving average smoothing if enabled
          if (CircadianConstants.sensorSmoothingEnabled) {
            if (_smoothedLux == null) {
              _smoothedLux = luxToProcess; // Initialize with first valid value
            } else {
              // EMA: smoothed = alpha * new + (1 - alpha) * old
              // If outlier was detected, luxToProcess is already partially smoothed
              _smoothedLux = CircadianConstants.sensorSmoothingFactor * luxToProcess + 
                            (1 - CircadianConstants.sensorSmoothingFactor) * _smoothedLux!;
            }
          } else {
            _smoothedLux = luxToProcess; // Use processed value if smoothing disabled
          }
        }
        // Always emit - don't block based on pause state
        // The OS will stop delivering events if it wants to pause sensors
        _emitSample();
      });
    } catch (e) {
      // Plugin not available or permission denied (common on some iOS devices)
      if (kDebugMode) {
        debugPrint('SensorService: Error subscribing to light sensor: $e');
      }
      _lastAmbientLux = null;
    }



    // Subscribe to accelerometer
    try {
      // Cancel existing subscription if any
      await _accelSub?.cancel();
      
      _accelSub = accelerometerEventStream().listen((AccelerometerEvent ev) {
        _lastAccelMag = sqrt(ev.x * ev.x + ev.y * ev.y + ev.z * ev.z);
        
        // Calculate pitch angle (rotation around x-axis)
        // Pitch = angle between device and horizontal plane
        // atan2(y, z) gives pitch in radians, where:
        // - 0° = device flat (screen facing up)
        // - 90° = device vertical (screen facing user)
        // - -90° = device upside down
        // For viewing angle, we want the angle from perpendicular to screen
        // When device is held normally (screen facing user), pitch ≈ 90°
        // Viewing angle = |90° - pitch| or |pitch - 90°|
        final pitchRadians = atan2(ev.y, sqrt(ev.x * ev.x + ev.z * ev.z));
        _lastPitch = pitchRadians;
        
        // Always emit - don't block based on pause state
        _emitSample();
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('SensorService: Error subscribing to accelerometer: $e');
      }
    }
  }

  Future<void> stop() async {
    _isStarted = false;
    _isPaused = false;
    
    try {
      await _luxSubscription?.cancel();
    } catch (_) {
      // ignore or log
    } finally {
      _luxSubscription = null;
    }

    try {
      await _accelSub?.cancel();
    } catch (_) {
      // ignore or log
    } finally {
      _accelSub = null;
    }
  }

  // todo: platform code should set this when screen changes
  void updateScreenState({required bool on, double? brightness}) {
    _screenOn = on;
    _screenBrightness = brightness;
    _emitSample();
  }

  void _emitSample() {
    // Use smoothed lux value if smoothing is enabled, otherwise use raw
    final luxToUse = CircadianConstants.sensorSmoothingEnabled 
        ? (_smoothedLux ?? _lastAmbientLux ?? 0.0)
        : (_lastAmbientLux ?? 0.0);
    
    final sample = LightSample(
      timestamp: DateTime.now().toUtc(),
      ambientLux: luxToUse,
      screenOn: _screenOn,
      screenBrightness: _screenBrightness,
      accelMagnitude: _lastAccelMag,
      orientationPitch: _lastPitch,
    );
    if (!_sampleController.isClosed) _sampleController.add(sample);
  }

  void dispose() {
    stop();
    _sampleController.close();
  }
}
