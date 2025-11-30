// lib/core/msi_model.dart

import 'dart:math';
import '../utils/constants.dart';

class MSIModel {
  final double k;

  const MSIModel({
    this.k = CircadianConstants.kDefault,
  });

  /// Calculate Melatonin Suppression Index
  ///
  /// MSI = 1 - exp(-k × X)
  ///
  /// Parameters:
  /// - X: dose (CS × time in hours)
  ///
  /// Returns: MSI fraction (0.0 to 1.0)
  double calculateMSI(double doseX) {
    if (doseX <= 0) return 0.0;

    final msi = 1 - exp(-k * doseX);
    return CircadianMath.clamp(msi, 0.0, 1.0);
  }

  /// Calculate dose X from CS timeline
  ///
  /// X = Σ CS(t_i) × Δt
  ///
  /// Parameters:
  /// - csValues: list of CS values at each time point
  /// - deltaT: time interval in hours
  static double calculateDose({
    required List<double> csValues,
    required double deltaT,
  }) {
    double dose = 0.0;
    for (final cs in csValues) {
      dose += cs * deltaT;
    }
    return dose;
  }

  /// Fit k from observed MSI and dose
  ///
  /// k = -ln(1 - MSI_obs) / X
  static double fitK({
    required double msiObserved,
    required double doseX,
  }) {
    if (doseX <= 0 || msiObserved >= 1.0) {
      return CircadianConstants.kDefault;
    }

    return -log(1 - msiObserved) / doseX;
  }

  /// Calculate MSI with uncertainty propagation
  /// Returns: {msi, lower_ci, upper_ci}
  Map<String, double> calculateMSIWithUncertainty({
    required double doseX,
    required double kUncertainty,
  }) {
    final msiMean = calculateMSI(doseX);
    final msiLower = 1 - exp(-(k - kUncertainty) * doseX);
    final msiUpper = 1 - exp(-(k + kUncertainty) * doseX);

    return {
      'msi': msiMean,
      'lower_ci': CircadianMath.clamp(msiLower, 0.0, 1.0),
      'upper_ci': CircadianMath.clamp(msiUpper, 0.0, 1.0),
    };
  }
}
