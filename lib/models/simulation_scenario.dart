// lib/models/simulation_scenario.dart

import 'package:flutter/foundation.dart';

/// Describes a "what-if" simulation the user wants to run
///
/// Examples:
/// - Reduce evening light by 50%
/// - Add 30 minutes of bright morning light at 08:00
/// - Shift all light exposure 1 hour earlier
@immutable
class SimulationScenario {
  /// ID of the original session being simulated
  final String baseSessionId;

  /// Human readable label, e.g. "Reduce evening light by 50%"
  final String name;

  /// Percentage change to apply to CS / melanopic exposure
  /// Negative = reduction, positive = increase.
  ///
  /// This is applied only within the affected time window.
  final double exposureChangePercent;

  /// Start of the window (hour-of-day, 0–23) where the change applies.
  /// Example: 19 = 7 PM local time.
  final int windowStartHour;

  /// End of the window (hour-of-day, 0–23) where the change applies.
  /// Example: 23 = 11 PM local time.
  ///
  /// If end < start, the window wraps over midnight.
  final int windowEndHour;

  /// Optional: add an extra block of bright light (e.g. morning therapy)
  /// Duration in minutes; 0 = no extra block.
  final int extraBlockMinutes;

  /// Clock time for extra block start (hour-of-day, 0–23).
  /// Only used if extraBlockMinutes > 0.
  final int? extraBlockStartHour;

  const SimulationScenario({
    required this.baseSessionId,
    required this.name,
    required this.exposureChangePercent,
    required this.windowStartHour,
    required this.windowEndHour,
    this.extraBlockMinutes = 0,
    this.extraBlockStartHour,
  }) : assert(windowStartHour >= 0 && windowStartHour <= 23),
       assert(windowEndHour >= 0 && windowEndHour <= 23);

  bool get hasExtraBlock => extraBlockMinutes > 0 && extraBlockStartHour != null;
}


