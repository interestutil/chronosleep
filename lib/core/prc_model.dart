// lib/core/prc_model.dart

import '../utils/constants.dart';
import '../utils/time_utils.dart';

class PRCModel {
  // PRC weights mapped by hour of day (simplified model)
  // Positive = phase advance, Negative = phase delay
  static const Map<int, double> _prcWeights = {
    0: -1.0, // midnight - strong delay
    1: -1.2, // 1 AM
    2: -1.5, // 2 AM - maximum delay
    3: -1.3, // 3 AM
    4: -0.8, // 4 AM
    5: -0.2, // 5 AM
    6: 0.3, // 6 AM - transition
    7: 0.8, // 7 AM - advancing
    8: 1.0, // 8 AM - maximum advance
    9: 0.9, // 9 AM
    10: 0.5, // 10 AM
    11: 0.2, // 11 AM
    12: 0.0, // noon - minimal effect
    13: 0.0, // 1 PM
    14: 0.0, // 2 PM
    15: 0.0, // 3 PM
    16: -0.1, // 4 PM
    17: -0.2, // 5 PM
    18: -0.3, // 6 PM
    19: -0.5, // 7 PM - starting delay
    20: -0.7, // 8 PM
    21: -0.8, // 9 PM
    22: -0.9, // 10 PM
    23: -1.0, // 11 PM
  };

  /// Get PRC weight for a given time
  static double getPRCWeight(DateTime time) {
    final hour = time.hour;
    return _prcWeights[hour] ?? 0.0;
  }

  /// Calculate phase shift for a single exposure event
  ///
  /// PhaseShift = PRC_weight(time) × scaling_factor × X
  ///
  /// Parameters:
  /// - time: when exposure occurred
  /// - doseX: CS × duration (CS·hours)
  ///
  /// Returns: phase shift in hours (positive = advance, negative = delay)
  static double calculatePhaseShift({
    required DateTime time,
    required double doseX,
  }) {
    if (doseX <= 0) return 0.0;

    final prcWeight = getPRCWeight(time);
    final scalingFactor = _getScalingFactor(time);

    return prcWeight * scalingFactor * doseX;
  }

  /// Get scaling factor based on time of day
  static double _getScalingFactor(DateTime time) {
    if (TimeUtils.isMorning(time)) {
      return CircadianConstants.scalingFactorMorning;
    } else if (TimeUtils.isEvening(time)) {
      return CircadianConstants.scalingFactorEvening;
    }
    return 0.5; // reduced effect during midday
  }

  /// Calculate cumulative phase shift from timeline
  ///
  /// Parameters:
  /// - times: list of exposure timestamps
  /// - doses: list of corresponding dose values (CS·Δt)
  static double calculateCumulativePhaseShift({
    required List<DateTime> times,
    required List<double> doses,
  }) {
    if (times.length != doses.length) {
      throw ArgumentError('times and doses must have same length');
    }

    double totalShift = 0.0;

    for (int i = 0; i < times.length; i++) {
      totalShift += calculatePhaseShift(
        time: times[i],
        doseX: doses[i],
      );
    }

    return totalShift;
  }

  /// Get interpretation of phase shift
  static String interpretPhaseShift(double shiftHours) {
    if (shiftHours.abs() < 0.1) {
      return 'Minimal circadian effect (< 6 minutes)';
    } else if (shiftHours > 0) {
      final minutes = (shiftHours * 60).round();
      return 'Phase advance of ~$minutes minutes (earlier sleep/wake)';
    } else {
      final minutes = (shiftHours.abs() * 60).round();
      return 'Phase delay of ~$minutes minutes (later sleep/wake)';
    }
  }
}
