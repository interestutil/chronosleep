// lib/services/simulation_service.dart
//
// Applies "what-if" changes on top of an existing session/results.

import 'dart:math';
import '../models/results_model.dart';
import '../models/simulation_scenario.dart';
import '../core/msi_model.dart';
import '../core/prc_model.dart';

class SimulationService {
  final MSIModel _msiModel;

  SimulationService({MSIModel? msiModel})
      : _msiModel = msiModel ?? const MSIModel();

  /// Run a simulation by modifying CS timeline according to the scenario.
  ///
  /// We:
  /// - scale CS values within the specified time window
  /// - optionally add an extra bright block in the morning
  /// - recompute dose X, MSI, and phase shift
  ResultsModel simulate({
    required ResultsModel base,
    required SimulationScenario scenario,
  }) {
    final timestamps = List<DateTime>.from(base.timestamps);
    final luxValues = List<double>.from(base.luxValues);
    final melanopicValues = List<double>.from(base.melanopicValues);
    final csValues = List<double>.from(base.csValues);

    // 1) Apply percentage change in the specified window
    final factor = 1.0 + scenario.exposureChangePercent / 100.0;

    for (int i = 0; i < timestamps.length; i++) {
      final hour = timestamps[i].hour;
      if (_isInWindow(hour, scenario.windowStartHour, scenario.windowEndHour)) {
        csValues[i] = max(0.0, csValues[i] * factor);
        melanopicValues[i] = max(0.0, melanopicValues[i] * factor);
        luxValues[i] = max(0.0, luxValues[i] * factor);
      }
    }

    // 2) Optionally add an extra block (e.g. bright morning light)
    final extraDoses = List<double>.filled(csValues.length, 0.0);
    if (scenario.hasExtraBlock) {
      _applyExtraBlock(
        timestamps: timestamps,
        csValues: csValues,
        extraMinutes: scenario.extraBlockMinutes,
        startHour: scenario.extraBlockStartHour!,
        extraDoses: extraDoses,
      );
    }

    // 3) Recompute dose X and MSI/phase-shift
    final durationHours =
        base.durationHours == 0 ? 1e-6 : base.durationHours; // avoid div by 0
    final deltaT = durationHours / csValues.length;

    final List<double> doses = [];
    for (int i = 0; i < csValues.length; i++) {
      final dose = csValues[i] * deltaT + extraDoses[i];
      doses.add(dose);
    }

    final totalDoseX =
        doses.isEmpty ? 0.0 : doses.reduce((a, b) => a + b); // CS·h
    final msiPredicted = _msiModel.calculateMSI(totalDoseX);

    final phaseShift = PRCModel.calculateCumulativePhaseShift(
      times: timestamps,
      doses: doses,
    );

    final averageCS =
        csValues.isEmpty ? 0.0 : csValues.reduce((a, b) => a + b) / csValues.length;
    final peakCS = csValues.isEmpty ? 0.0 : csValues.reduce(max);
    final averageMelanopicLux = melanopicValues.isEmpty
        ? 0.0
        : melanopicValues.reduce((a, b) => a + b) / melanopicValues.length;

    return ResultsModel(
      sessionId: '${base.sessionId}::sim',
      startTime: base.startTime,
      endTime: base.endTime,
      durationHours: base.durationHours,
      timestamps: timestamps,
      luxValues: luxValues,
      melanopicValues: melanopicValues,
      csValues: csValues,
      totalDoseX: totalDoseX,
      msiPredicted: msiPredicted,
      phaseShift: phaseShift,
      averageCS: averageCS,
      peakCS: peakCS,
      averageMelanopicLux: averageMelanopicLux,
      lightType: base.lightType,
      metadata: {
        ...?base.metadata,
        'simulationName': scenario.name,
        'exposureChangePercent': scenario.exposureChangePercent,
        'windowStartHour': scenario.windowStartHour,
        'windowEndHour': scenario.windowEndHour,
        'extraBlockMinutes': scenario.extraBlockMinutes,
        'extraBlockStartHour': scenario.extraBlockStartHour,
      },
    );
  }

  bool _isInWindow(int hour, int start, int end) {
    if (start <= end) {
      return hour >= start && hour < end;
    }
    // Wrap over midnight
    return hour >= start || hour < end;
  }

  void _applyExtraBlock({
    required List<DateTime> timestamps,
    required List<double> csValues,
    required int extraMinutes,
    required int startHour,
    required List<double> extraDoses,
  }) {
    if (extraMinutes <= 0 || csValues.isEmpty) return;

    final durationHours = extraMinutes / 60.0;
    final perSample = durationHours / csValues.length;

    for (int i = 0; i < timestamps.length; i++) {
      if (timestamps[i].hour == startHour) {
        extraDoses[i] += perSample * max(0.0, csValues[i]);
      }
    }
  }
}


