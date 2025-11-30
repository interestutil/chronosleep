// lib/core/cs_model.dart

import 'dart:math';
import '../utils/constants.dart';

class CSModel {
  final double csMax;
  final double a;

  const CSModel({
    this.csMax = CircadianConstants.csMax,
    this.a = CircadianConstants.aDefault,
  });

  /// Calculate CS using saturating exponential model (Rea et al.)
  ///
  /// CS = CS_max * (1 - exp(-a * melanopic_EDI))
  ///
  /// Parameters:
  /// - melanopicEDI: melanopic lux value
  ///
  /// Returns: Circadian Stimulus (0.0 to ~0.7)
  double calculateCS(double melanopicEDI) {
    if (melanopicEDI <= 0) return 0.0;

    final cs = csMax * (1 - exp(-a * melanopicEDI));
    return CircadianMath.clamp(cs, 0.0, csMax);
  }

  /// Calculate CS using simple linear approximation (fallback)
  ///
  /// CS = min(melanopic_EDI / 1000, CS_max)
  static double calculateCSLinear(double melanopicEDI) {
    return CircadianMath.clamp(
      melanopicEDI / 1000.0,
      0.0,
      CircadianConstants.csMax,
    );
  }

  /// Fit parameter 'a' from a single observation
  ///
  /// Given: melanopicEDI_obs and CS_obs, solve for 'a'
  /// a = -ln(1 - CS_obs/CS_max) / melanopicEDI_obs
  static double fitParameterA({
    required double melanopicEDI,
    required double csObserved,
    double csMax = CircadianConstants.csMax,
  }) {
    if (melanopicEDI <= 0 || csObserved >= csMax) {
      return CircadianConstants.aDefault;
    }

    final ratio = csObserved / csMax;
    if (ratio >= 1.0) return CircadianConstants.aDefault;

    return -log(1 - ratio) / melanopicEDI;
  }
}
