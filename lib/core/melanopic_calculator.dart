// lib/core/melanopic_calculator.dart

import 'dart:math';
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
      final screenLux = estimateScreenLux(
        brightness: sample.screenBrightness!,
        viewingDistanceCm: null, // Uses CircadianConstants.viewingDistanceCm
        viewingAngleRadians: sample.orientationPitch,
      );
      totalLux += screenLux;
    }

    return totalLux;
  }

  /// Estimate screen lux at eye from brightness level, accounting for distance and viewing angle
  ///
  /// Uses physics-based calculations:
  /// - Inverse square law: lux ∝ 1/distance²
  /// - Cosine law: lux ∝ cos(viewing_angle)
  ///
  /// Parameters:
  /// - brightness: Screen brightness (0.0 - 1.0)
  /// - viewingDistanceCm: Distance from eye to screen in cm (optional, uses constant if null)
  /// - viewingAngleRadians: Angle from perpendicular to screen in radians (optional)
  ///
  /// Returns: Lux at eye accounting for distance and angle
  static double estimateScreenLux({
    required double brightness,
    double? viewingDistanceCm,
    double? viewingAngleRadians,
  }) {
    // Get base lux at reference distance (perpendicular viewing)
    final baseLux = CircadianMath.interpolateFromMap(
      CircadianConstants.screenBrightnessToLux,
      brightness,
    );
    
    if (baseLux <= 0) return 0.0;
    
    // Use default viewing distance if not provided
    final distanceCm = viewingDistanceCm ?? CircadianConstants.viewingDistanceCm;
    const referenceDistanceCm = CircadianConstants.referenceViewingDistanceCm;
    
    // Apply inverse square law for distance
    // lux_at_distance = lux_at_reference × (reference_distance² / actual_distance²)
    final distanceFactor = (referenceDistanceCm * referenceDistanceCm) / 
                          (distanceCm * distanceCm);
    
    // Apply cosine law for viewing angle
    // lux_at_angle = lux_perpendicular × cos(angle)
    // Viewing angle is measured from perpendicular (0° = perpendicular, 90° = parallel)
    double angleFactor = 1.0;
    if (viewingAngleRadians != null) {
      // Convert pitch to viewing angle
      // When device is held normally (screen facing user), pitch ≈ π/2 (90°)
      // Viewing angle = |pitch - π/2|, clamped to [0, π/2]
      const normalPitch = pi / 2.0; // 90 degrees (device vertical, screen facing user)
      final angleFromNormal = (viewingAngleRadians - normalPitch).abs();
      final viewingAngle = angleFromNormal.clamp(0.0, pi / 2.0);
      
      // Cosine law: lux decreases with cos(angle)
      // Clamp to prevent negative values
      angleFactor = cos(viewingAngle).clamp(0.0, 1.0);
    }
    
    // Combined effect: lux_at_eye = base_lux × distance_factor × angle_factor
    final luxAtEye = baseLux * distanceFactor * angleFactor;
    
    return luxAtEye;
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
