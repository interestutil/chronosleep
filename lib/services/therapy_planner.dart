// lib/services/therapy_planner.dart
//
// Generates a simple chronotherapy plan from current circadian metrics.

import '../models/results_model.dart';
import '../models/chrono_plan.dart';

class TherapyPlanner {
  const TherapyPlanner();

  /// Generate a basic plan from a results object.
  ///
  /// This does not try to be clinically precise; it turns
  /// MSI + phase shift + timing into clear, actionable text.
  ChronoPlan generatePlan(ResultsModel results) {
    final msi = results.msiPredicted;
    final shift = results.phaseShift; // hours, +advance / -delay
    final startHour = results.startTime.hour;

    final title = _buildTitle(msi, shift, startHour);
    final description = _buildDescription(msi, shift, startHour);

    final morningLightBlock = _buildMorningLightBlock(shift);
    final eveningDimBlock = _buildEveningDimBlock(msi, startHour);
    final idealBedtime = _estimateIdealBedtime(startHour, shift);
    final screenGuidance = _buildScreenGuidance(startHour, msi);
    final recoveryTimeline = _buildRecoveryTimeline(shift);

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

  String _buildTitle(double msi, double shift, int hour) {
    if (shift > 0.25) {
      return 'Advance your sleep phase';
    } else if (shift < -0.25) {
      return 'Reduce late-night circadian delay';
    } else if (hour >= 19 || hour < 4) {
      return 'Protect your biological night';
    } else {
      return 'Maintain healthy circadian light exposure';
    }
  }

  String _buildDescription(double msi, double shift, int hour) {
    final msiPct = (msi * 100).toStringAsFixed(1);
    final minutes = (shift.abs() * 60).round();
    final direction = shift > 0 ? 'earlier' : 'later';

    final buffer = StringBuffer();
    buffer.write(
        'This session produced an estimated $msiPct% melatonin suppression ');
    if (shift.abs() >= 0.1) {
      buffer.write(
          'and shifted your circadian phase about $minutes minutes $direction. ');
    } else {
      buffer.write('with minimal direct phase-shifting effect. ');
    }

    if (hour >= 19 || hour < 4) {
      buffer.write(
          'Because this occurred during your biological evening/night, we will focus on reducing disruptive light before bed and strengthening your morning light signal.');
    } else if (hour >= 4 && hour < 11) {
      buffer.write(
          'Because this exposure occurred in the morning window, we can use it to gently advance your clock and anchor your day.');
    } else {
      buffer.write(
          'Daytime exposure is generally helpful; your main goal is to avoid strong circadian light at night and secure consistent morning light.');
    }

    return buffer.toString();
  }

  String _buildMorningLightBlock(double shift) {
    // Stronger morning recommendation if we want to advance
    if (shift < -0.1) {
      return 'Aim for 30–45 minutes of bright light (≥1,000 lux; outdoor light or bright window) between 07:00 and 09:00 to counteract the delay.';
    } else if (shift > 0.1) {
      return 'Maintain 20–30 minutes of bright light (≥1,000 lux) between 07:00 and 09:00 to support an earlier sleep schedule.';
    } else {
      return 'Target 20–30 minutes of bright light (≥1,000 lux) in the first 2 hours after waking to keep your circadian clock stable.';
    }
  }

  String _buildEveningDimBlock(double msi, int hour) {
    if (hour >= 19 || hour < 1 || msi > 0.2) {
      return 'Create a “dim light zone”: keep melanopic lux <20 (very dim, warm light) starting 2–3 hours before your target bedtime.';
    }
    return 'In the 2 hours before bed, prefer warm, low-intensity light and avoid bright overhead lighting.';
  }

  String _estimateIdealBedtime(int hour, double shift) {
    // Use recording start hour as proxy for current schedule.
    // If delay, suggest slightly earlier target; if advance, keep or slightly maintain.
    var targetHour = hour;
    if (hour < 18) {
      targetHour = 23; // daytime recording: assume ~23:00 bedtime
    } else if (hour >= 18 && hour < 22) {
      targetHour = hour + 3; // evening recording: +3h → approximate bedtime
      if (targetHour >= 24) targetHour -= 24;
    } else {
      targetHour = (hour + 1) % 24;
    }

    // Adjust by a small fraction of the predicted shift (do not overshoot)
    final adjustHours = (-shift).clamp(-1.0, 1.0); // move towards desired
    targetHour = (targetHour + adjustHours).round() % 24;

    final hh = targetHour.toString().padLeft(2, '0');
    return 'Aim for a consistent bedtime around $hh:00 each night.';
  }

  String _buildScreenGuidance(int hour, double msi) {
    if (hour >= 19 || hour < 4) {
      if (msi > 0.2) {
        return 'Avoid blue-rich screens (phones, laptops, TVs) in the 2–3 hours before bed. '
            'If you must use screens, enable strong blue-light filters or use amber glasses.';
      }
      return 'Try to keep screens out of bed and finish stimulating content at least 1 hour before sleep.';
    }
    return 'Use screens freely in daytime, but avoid carrying heavy screen use into the late evening.';
  }

  String _buildRecoveryTimeline(double shift) {
    final absShift = shift.abs();
    if (absShift < 0.1) {
      return 'With consistent light hygiene, your circadian rhythm should remain stable over the coming week.';
    } else if (absShift < 0.5) {
      return 'With the suggested plan, expect your internal clock to realign over ~3–5 days of consistent timing.';
    } else {
      return 'Larger phase shifts typically require 5–10 days of consistent light timing and sleep schedule to fully stabilize.';
    }
  }
}


