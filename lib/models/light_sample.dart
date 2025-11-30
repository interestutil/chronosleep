// lib/models/light_sample.dart
import 'package:flutter/foundation.dart';

/// LightSample: single time-stamped sensor reading
@immutable
class LightSample {
  final DateTime timestamp;
  final double ambientLux; // lux from ambient light sensor
  final bool screenOn; // true if screen is on
  final double? screenBrightness; // 0.0..1.0 (nullable if not available)
  final double?
  accelMagnitude; // optionally include aggregated accelerometer magnitude
  final double? orientationPitch; // orientation data small set

  const LightSample({
    required this.timestamp,
    required this.ambientLux,
    required this.screenOn,
    this.screenBrightness,
    this.accelMagnitude,
    this.orientationPitch,
  });

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'ambientLux': ambientLux,
    'screenOn': screenOn ? 1 : 0,
    'screenBrightness': screenBrightness,
    'accelMagnitude': accelMagnitude,
    'orientationPitch': orientationPitch,
  };

  static LightSample fromJson(Map<String, dynamic> j) => LightSample(
    timestamp: DateTime.parse(j['timestamp'] as String),
    ambientLux: (j['ambientLux'] as num).toDouble(),
    screenOn: (j['screenOn'] as int) == 1,
    screenBrightness: j['screenBrightness'] == null
        ? null
        : (j['screenBrightness'] as num).toDouble(),
    accelMagnitude: j['accelMagnitude'] == null
        ? null
        : (j['accelMagnitude'] as num).toDouble(),
    orientationPitch: j['orientationPitch'] == null
        ? null
        : (j['orientationPitch'] as num).toDouble(),
  );
}
