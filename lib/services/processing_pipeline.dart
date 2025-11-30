// lib/services/processing_pipeline.dart

import 'dart:math';
import '../models/session_data.dart';
import '../models/results_model.dart';
import '../models/light_sample.dart';
import '../core/melanopic_calculator.dart';
import '../core/cs_model.dart';
import '../core/msi_model.dart';
import '../core/prc_model.dart';
import '../utils/time_utils.dart';

class ProcessingPipeline {
  final CSModel csModel;
  final MSIModel msiModel;

  ProcessingPipeline({
    CSModel? csModel,
    MSIModel? msiModel,
  })  : csModel = csModel ?? const CSModel(),
        msiModel = msiModel ?? const MSIModel();

  /// Process a complete session and return results
  Future<ResultsModel> process({
    required SessionData session,
    String lightType = 'neutral_led_4000k',
  }) async {
    if (session.samples.isEmpty) {
      throw ArgumentError('Session has no samples');
    }

    // 1. Calculate time parameters
    final durationHours = TimeUtils.durationInHours(
      session.startedAt,
      session.stoppedAt,
    );

    // Estimate deltaT from samples
    final deltaT = _estimateDeltaT(session.samples);

    // 2. Process each sample
    final List<DateTime> timestamps = [];
    final List<double> luxValues = [];
    final List<double> melanopicValues = [];
    final List<double> csValues = [];
    final List<double> doses = [];

    for (final sample in session.samples) {
      // Calculate total lux at eye
      final totalLux = MelanopicCalculator.calculateTotalLuxAtEye(sample);

      // Calculate melanopic EDI
      final melanopicEDI = MelanopicCalculator.calculateMelanopicEDI(
        totalLux: totalLux,
        lightType: lightType,
      );

      // Calculate CS
      final cs = csModel.calculateCS(melanopicEDI);

      // Calculate dose for this bin
      final dose = cs * deltaT;

      timestamps.add(sample.timestamp);
      luxValues.add(totalLux);
      melanopicValues.add(melanopicEDI);
      csValues.add(cs);
      doses.add(dose);
    }

    // 3. Calculate integrated metrics
    final totalDoseX = doses.reduce((a, b) => a + b);
    final msiPredicted = msiModel.calculateMSI(totalDoseX);

    // 4. Calculate phase shift
    final phaseShift = PRCModel.calculateCumulativePhaseShift(
      times: timestamps,
      doses: doses,
    );

    // 5. Calculate summary statistics
    final averageCS = csValues.reduce((a, b) => a + b) / csValues.length;
    final peakCS = csValues.reduce(max);
    final averageMelanopicLux =
        melanopicValues.reduce((a, b) => a + b) / melanopicValues.length;

    // 6. Create results model
    return ResultsModel(
      sessionId: session.id,
      startTime: session.startedAt,
      endTime: session.stoppedAt,
      durationHours: durationHours,
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
      lightType: lightType,
      metadata: session.meta,
    );
  }

  /// Estimate deltaT (time bin size) from samples
  double _estimateDeltaT(List<LightSample> samples) {
    if (samples.length < 2) return 1.0 / 60.0; // default 1 minute

    // Calculate average interval between samples
    double totalSeconds = 0.0;
    for (int i = 1; i < samples.length; i++) {
      totalSeconds +=
          samples[i].timestamp.difference(samples[i - 1].timestamp).inSeconds;
    }

    final avgSeconds = totalSeconds / (samples.length - 1);
    return avgSeconds / 3600.0; // convert to hours
  }
}
