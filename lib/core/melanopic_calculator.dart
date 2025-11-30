// lib/core/melanopic_calculator.dart

import '../utils/constants.dart';
import '../models/light_sample.dart';

class MelanopicCalculator {
  /// Calculate melanopic EDI from total lux and light type
  ///
  /// Parameters:
  /// - totalLux: photopic lux (what light sensor measures)
  /// - lightType: key from CircadianConstants.melanopicRatios
  ///
  /// Returns: melanopic equivalent daylight illuminance (melanopic lux)
  static double calculateMelanopicEDI({
    required double totalLux,
    required String lightType,
  }) {
    final ratio = CircadianConstants.melanopicRatios[lightType] ?? 0.6;
    return totalLux * ratio;
  }

  /// Calculate total lux at eye from sample
  ///
  /// Combines ambient lux with screen contribution if screen is on
  static double calculateTotalLuxAtEye(LightSample sample) {
    double totalLux = sample.ambientLux;

    // Add screen contribution if screen is on
    if (sample.screenOn && sample.screenBrightness != null) {
      final screenLux = estimateScreenLux(sample.screenBrightness!);
      totalLux += screenLux;
    }

    return totalLux;
  }

  /// Estimate screen lux from brightness level
  static double estimateScreenLux(double brightness) {
    return CircadianMath.interpolateFromMap(
      CircadianConstants.screenBrightnessToLux,
      brightness,
    );
  }

  /// Process a single sample to get melanopic EDI
  static double processSample({
    required LightSample sample,
    required String lightType,
  }) {
    final totalLux = calculateTotalLuxAtEye(sample);
    return calculateMelanopicEDI(
      totalLux: totalLux,
      lightType: lightType,
    );
  }
}
