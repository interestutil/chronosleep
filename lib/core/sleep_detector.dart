// lib/core/sleep_detector.dart
//
// Very simple actigraphy-based sleep detection heuristic for longer sessions.

import '../models/light_sample.dart';

class SleepEpisode {
  final DateTime start;
  final DateTime end;
  const SleepEpisode({required this.start, required this.end});
}

class SleepDetector {
  /// Detects periods of very low movement and low light as proxy for sleep.
  ///
  /// This is a heuristic and mainly for demonstration; most user-triggered
  /// sessions will be fully awake.
  static List<SleepEpisode> detect(List<LightSample> samples) {
    if (samples.isEmpty) return const [];

    const accelThreshold = 0.5; // very low movement
    const luxThreshold = 10.0; // very dim
    const minDurationMinutes = 20;

    final episodes = <SleepEpisode>[];
    DateTime? currentStart;

    for (int i = 0; i < samples.length; i++) {
      final s = samples[i];
      final lowAccel =
          (s.accelMagnitude ?? 0.0).abs() < accelThreshold; // crude
      final lowLight = s.ambientLux < luxThreshold;

      final isCandidate = lowAccel && lowLight;

      if (isCandidate && currentStart == null) {
        currentStart = s.timestamp;
      } else if (!isCandidate && currentStart != null) {
        final end = s.timestamp;
        final minutes =
            end.difference(currentStart).inMinutes;
        if (minutes >= minDurationMinutes) {
          episodes.add(SleepEpisode(start: currentStart, end: end));
        }
        currentStart = null;
      }
    }

    return episodes;
  }
}


