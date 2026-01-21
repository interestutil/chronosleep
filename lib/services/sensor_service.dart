// lib/services/sensor_service.dart
import 'dart:async';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:light/light.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../models/light_sample.dart';

class SensorService {
  // Singletons or instance via provider
  final _lightPlugin = Light();
  StreamSubscription<dynamic>? _luxSubscription;
  StreamSubscription<AccelerometerEvent>? _accelSub;

  final StreamController<LightSample> _sampleController =
      StreamController.broadcast();
  Stream<LightSample> get sampleStream => _sampleController.stream;

  double? _lastAmbientLux;
  double _lastAccelMag = 0.0;
  bool _screenOn = true;
  double? _screenBrightness; // read via platform channel

  /// start sensors
  Future<void> start() async {
    // subscribe to ambient light (Android)
    try {
      _luxSubscription =
          _lightPlugin.lightSensorStream.listen((dynamic luxVal) {
        if (luxVal is num) {
          _lastAmbientLux = luxVal.toDouble();
        }
        _emitSample();
      });
    } catch (e) {
      // Plugin not available or permission denied (common on some iOS devices)
      _lastAmbientLux = null;
    }

    // accelerometer
    // ignore: deprecated_member_use
    //! The flutter sdk has been updated, DO NOT CHANGE THE VERSION (stick with the deprecated one)
    _accelSub = accelerometerEvents.listen((AccelerometerEvent ev) {
      _lastAccelMag = sqrt(ev.x * ev.x + ev.y * ev.y + ev.z * ev.z);
      _emitSample();
    });

    // *no await needed here beyond subscribing
  }

  Future<void> stop() async {
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
    final sample = LightSample(
      timestamp: DateTime.now().toUtc(),
      ambientLux: _lastAmbientLux ?? 0.0,
      screenOn: _screenOn,
      screenBrightness: _screenBrightness,
      accelMagnitude: _lastAccelMag,
      orientationPitch: null,
    );
    if (!_sampleController.isClosed) _sampleController.add(sample);
  }

  void dispose() {
    stop();
    _sampleController.close();
  }
}
