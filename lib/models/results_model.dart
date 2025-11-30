// lib/models/results_model.dart

import 'package:flutter/foundation.dart';

@immutable
class ResultsModel {
  final String sessionId;
  final DateTime startTime;
  final DateTime endTime;
  final double durationHours;

  // Timelines (for charts)
  final List<DateTime> timestamps;
  final List<double> luxValues;
  final List<double> melanopicValues;
  final List<double> csValues;

  // Computed metrics
  final double totalDoseX;
  final double msiPredicted;
  final double phaseShift;
  final double averageCS;
  final double peakCS;
  final double averageMelanopicLux;

  // Metadata
  final String lightType;
  final Map<String, dynamic>? metadata;

  const ResultsModel({
    required this.sessionId,
    required this.startTime,
    required this.endTime,
    required this.durationHours,
    required this.timestamps,
    required this.luxValues,
    required this.melanopicValues,
    required this.csValues,
    required this.totalDoseX,
    required this.msiPredicted,
    required this.phaseShift,
    required this.averageCS,
    required this.peakCS,
    required this.averageMelanopicLux,
    required this.lightType,
    this.metadata,
  });

  /// Get circadian health score (0-100)
  double get healthScore {
    // Higher MSI at wrong times = lower score
    // Ideal: low MSI in evening, higher in morning

    final eveningSamples =
        timestamps.where((t) => t.hour >= 19 || t.hour < 4).length;
    final totalSamples = timestamps.length;

    if (totalSamples == 0) return 50.0;

    final eveningRatio = eveningSamples / totalSamples;

    // Penalize high MSI if mostly evening exposure
    if (eveningRatio > 0.5 && msiPredicted > 0.15) {
      return 100 * (1 - msiPredicted * eveningRatio);
    }

    // Reward moderate daytime exposure
    return 100 * (1 - msiPredicted.abs() * 0.3).clamp(0.0, 1.0);
  }

  /// Get risk level interpretation
  String get riskLevel {
    if (msiPredicted > 0.4) return 'High circadian disruption risk';
    if (msiPredicted > 0.2) return 'Moderate circadian impact';
    if (msiPredicted > 0.1) return 'Low circadian impact';
    return 'Minimal circadian effect';
  }

  Map<String, dynamic> toJson() => {
        'sessionId': sessionId,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime.toIso8601String(),
        'durationHours': durationHours,
        'totalDoseX': totalDoseX,
        'msiPredicted': msiPredicted,
        'phaseShift': phaseShift,
        'averageCS': averageCS,
        'peakCS': peakCS,
        'averageMelanopicLux': averageMelanopicLux,
        'lightType': lightType,
        'healthScore': healthScore,
        'riskLevel': riskLevel,
        'metadata': metadata,
      };
}
