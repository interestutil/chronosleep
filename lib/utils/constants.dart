// lib/utils/constants.dart

class CircadianConstants {
  // Model parameters
  static const double kDefault = 0.25; // Sensitivity constant
  static const double csMax = 0.7; // Maximum circadian stimulus
  static const double aDefault = 0.005; // CS curve steepness (1/melanopic-lux)

  // PRC scaling
  static const double scalingFactorMorning = 1.0; // hours per CS·hour
  static const double scalingFactorEvening = 0.9; // hours per CS·hour

  // Sampling
  static const Duration defaultSamplingInterval = Duration(seconds: 60);

  // Melanopic ratios for common light sources
  static const Map<String, double> melanopicRatios = {
    'warm_led_2700k': 0.45,
    'neutral_led_4000k': 0.60,
    'cool_led_5000k': 0.85,
    'daylight_6500k': 0.95,
    'phone_screen': 0.75,
    'incandescent': 0.42,
  };

  // Safety limits
  static const double maxSafeLux = 10000.0;
  static const Duration maxContinuousExposure = Duration(hours: 2);

  // Screen brightness to lux mapping (approximate)
  static Map<double, double> screenBrightnessToLux = {
    0.0: 0.0,
    0.2: 40.0,
    0.4: 80.0,
    0.5: 120.0,
    0.6: 160.0,
    0.8: 220.0,
    1.0: 300.0,
  };
}

class CircadianMath {
  /// Linear interpolation
  static double lerp(double a, double b, double t) {
    return a + (b - a) * t;
  }

  /// Clamp value between min and max
  static double clamp(double value, double min, double max) {
    return value < min ? min : (value > max ? max : value);
  }

  /// Interpolate from a map (e.g., brightness → lux)
  static double interpolateFromMap(Map<double, double> map, double key) {
    if (map.isEmpty) return 0.0;

    final sortedKeys = map.keys.toList()..sort();

    if (key <= sortedKeys.first) return map[sortedKeys.first]!;
    if (key >= sortedKeys.last) return map[sortedKeys.last]!;

    for (int i = 0; i < sortedKeys.length - 1; i++) {
      final k1 = sortedKeys[i];
      final k2 = sortedKeys[i + 1];

      if (key >= k1 && key <= k2) {
        final t = (key - k1) / (k2 - k1);
        return lerp(map[k1]!, map[k2]!, t);
      }
    }

    return map[sortedKeys.last]!;
  }
}
