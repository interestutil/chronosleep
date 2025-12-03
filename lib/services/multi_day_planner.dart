// lib/services/multi_day_planner.dart
//
// Very simple multi-day chronotherapy planning using recent ResultsModel list.

import '../models/results_model.dart';
import '../models/chrono_plan.dart';
import '../core/clock_model.dart';

class MultiDayPlanner {
  final ClockModel _clockModel = const ClockModel();

  /// Given a chronological list of daily results, produce a high-level plan.
  ChronoPlan planFromHistory(List<ResultsModel> history) {
    if (history.isEmpty) {
      return const ChronoPlan(
        title: 'Not enough data',
        description:
            'Record several sessions across different days to generate a multi-day chronotherapy plan.',
        morningLightBlock:
            'Aim for 20–30 minutes of bright light in the first 2 hours after waking.',
        eveningDimBlock:
            'Keep light dim and warm in the 2–3 hours before bedtime.',
        idealBedtime: 'Keep a consistent bedtime and wake time.',
        screenGuidance:
            'Avoid bright screens in bed; finish stimulating content at least 1 hour before sleep.',
        recoveryTimeline:
            'Once you have more data, the app can estimate how many days are needed for realignment.',
      );
    }

    // Aggregate net phase shift over history.
    var state = const ClockState(phaseOffsetHours: 0.0);
    for (final r in history) {
      state = _clockModel.applyShift(state, r.phaseShift);
    }

    final netShift = state.phaseOffsetHours;
    final absShift = netShift.abs();

    String title;
    if (netShift > 0.5) {
      title = 'Advance your circadian phase over several days';
    } else if (netShift < -0.5) {
      title = 'Correct a delayed circadian phase over several days';
    } else {
      title = 'Stabilize your circadian rhythm';
    }

    final description =
        'Based on your recent recordings, your internal clock appears to be shifted by '
        '${(netShift * 60).round()} minutes relative to local time. '
        'This plan uses repeated morning light and evening dimming to gradually realign it.';

    final morningLightBlock =
        'For the next 7–10 days, get 30–45 minutes of bright light (≥1,000 lux) '
        'within 1–2 hours of waking. Outdoor daylight works best.';

    final eveningDimBlock =
        'Each evening, create a “dim light zone” starting 2–3 hours before your target bedtime: '
        'use warm, low-intensity lighting and minimize overhead lights.';

    final idealBedtime =
        'Choose a target bedtime and wake time that you can keep consistent for at least a week.';

    final screenGuidance =
        'Stop using bright screens 1–2 hours before bed, or use strong blue-light filters / amber glasses.';

    String recoveryTimeline;
    if (absShift < 0.5) {
      recoveryTimeline =
          'With consistent light timing, you should stabilize within 3–5 days.';
    } else if (absShift < 1.5) {
      recoveryTimeline =
          'Expect 5–10 days of consistent behavior to bring your clock closer to local time.';
    } else {
      recoveryTimeline =
          'For larger shifts, plan on 10–14 days of structured light exposure and sleep timing.';
    }

    return ChronoPlan(
      title: title,
      description: description,
      morningLightBlock: morningLightBlock,
      eveningDimBlock: eveningDimBlock,
      idealBedtime: idealBedtime,
      screenGuidance: screenGuidance,
      recoveryTimeline: recoveryTimeline,
    );
  }
}


