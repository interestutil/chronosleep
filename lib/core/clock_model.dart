// lib/core/clock_model.dart
//
// Simple circadian clock model scaffold using cumulative phase shifts.

class ClockState {
  /// Estimated internal phase offset in hours relative to local time.
  /// Positive = internal clock ahead, negative = delayed.
  final double phaseOffsetHours;

  const ClockState({required this.phaseOffsetHours});

  ClockState copyWith({double? phaseOffsetHours}) =>
      ClockState(phaseOffsetHours: phaseOffsetHours ?? this.phaseOffsetHours);
}

class ClockModel {
  const ClockModel();

  /// Update clock state given a predicted phase shift (hours).
  ClockState applyShift(ClockState state, double shiftHours) {
    return state.copyWith(
      phaseOffsetHours: state.phaseOffsetHours + shiftHours,
    );
  }
}


