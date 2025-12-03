// lib/models/chrono_plan.dart

import 'package:flutter/foundation.dart';

/// A simple chronotherapy plan generated from a session or simulation.
@immutable
class ChronoPlan {
  /// Short title, e.g. "Advance sleep phase by ~30 minutes"
  final String title;

  /// Free-text description of the goal and rationale.
  final String description;

  /// Morning light exposure recommendation, e.g.
  /// "Expose to 5,000–10,000 lux for 20 minutes between 7:00–7:30 AM."
  final String morningLightBlock;

  /// Evening dim-light recommendation, e.g.
  /// "Reduce melanopic lux to <20 lux 2 hours before sleep."
  final String eveningDimBlock;

  /// Suggested ideal bedtime (human readable).
  final String idealBedtime;

  /// Screen use guidance string.
  final String screenGuidance;

  /// Rough recovery / improvement timeline.
  final String recoveryTimeline;

  const ChronoPlan({
    required this.title,
    required this.description,
    required this.morningLightBlock,
    required this.eveningDimBlock,
    required this.idealBedtime,
    required this.screenGuidance,
    required this.recoveryTimeline,
  });
}


