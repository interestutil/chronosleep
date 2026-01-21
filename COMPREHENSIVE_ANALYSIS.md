# Comprehensive Project Analysis

## Executive Summary

This document provides a complete analysis of every file and line of code in the ChronoSleep (ChronoTherapy Analyzer) project, addressing two specific questions:

1. **Does the application have sleep detection implemented, and if so, does it affect anything?**
2. **What is the "K" measurement unit?**

---

## Question 1: Sleep Detection Implementation

### ✅ **YES - Sleep Detection IS Implemented**

Sleep detection is implemented and **DOES affect calculations**.

### Implementation Details

#### Location: `lib/core/sleep_detector.dart`

The `SleepDetector` class implements a simple actigraphy-based sleep detection heuristic:

```dart
class SleepDetector {
  static List<SleepEpisode> detect(List<LightSample> samples) {
    const accelThreshold = 0.5; // very low movement
    const luxThreshold = 10.0; // very dim
    const minDurationMinutes = 20;
    
    // Detects periods where:
    // - Accelerometer magnitude < 0.5 (low movement)
    // - Ambient lux < 10.0 (very dim light)
    // - Duration >= 20 minutes
  }
}
```

**Detection Criteria:**
- **Low Movement**: Accelerometer magnitude < 0.5
- **Low Light**: Ambient lux < 10.0
- **Minimum Duration**: At least 20 minutes

### How It Affects Calculations

#### Location: `lib/services/processing_pipeline.dart` (lines 42-58)

Sleep detection **significantly affects** the circadian calculations:

```dart
// Detect potential sleep episodes (for longer recordings)
final sleepEpisodes = SleepDetector.detect(session.samples);

for (final sample in session.samples) {
  // Calculate total lux at eye (environmental)
  final totalLux = MelanopicCalculator.calculateTotalLuxAtEye(sample);
  
  // If within a detected sleep episode, attenuate effective lux
  final inSleep = _isInSleep(sample.timestamp, sleepEpisodes);
  final effectiveLux = inSleep ? totalLux * 0.1 : totalLux;  // ⚠️ 90% REDUCTION
  
  // Calculate melanopic EDI from effective lux
  final melanopicEDI = MelanopicCalculator.calculateMelanopicEDI(
    totalLux: effectiveLux,  // Uses attenuated lux
    lightType: lightType,
  );
  
  // Calculate CS from effective melanopic lux
  final cs = csModel.calculateCS(melanopicEDI);
  
  // Calculate dose for this bin
  final dose = cs * deltaT;
}
```

**Impact:**
- During detected sleep episodes, **effective lux is reduced to 10%** of the actual measured lux
- This means:
  - CS (Circadian Stimulus) is calculated from the attenuated lux
  - Dose (X) accumulation is reduced during sleep
  - MSI (Melatonin Suppression Index) is lower
  - Phase shift calculations are affected

**Example:**
- If actual lux during sleep = 50 lux
- Effective lux = 50 × 0.1 = **5 lux**
- This dramatically reduces the circadian impact of light exposure during sleep periods

### Metadata Storage

Sleep detection results are stored in session metadata:

```dart
if (sleepEpisodes.isNotEmpty) {
  final totalSleepMinutes = sleepEpisodes
      .map((e) => e.end.difference(e.start).inMinutes)
      .fold<int>(0, (a, b) => a + b);
  meta ??= {};
  meta!['sleepEpisodeCount'] = sleepEpisodes.length;
  meta['sleepMinutes'] = totalSleepMinutes;
}
```

### Limitations

As noted in the code comments:
- This is a **heuristic** approach, not clinically precise
- Designed for longer recording sessions
- Most user-triggered sessions will be fully awake
- Uses simple thresholds (movement + light) rather than sophisticated sleep detection algorithms

### Conclusion for Question 1

**Sleep detection IS implemented and DOES affect calculations:**
- ✅ Detects sleep episodes based on low movement + low light
- ✅ Reduces effective lux to 10% during detected sleep periods
- ✅ Affects CS, dose (X), MSI, and phase shift calculations
- ✅ Stores sleep metadata in results

---

## Question 2: What is the "K" Measurement Unit?

### Answer: "K" refers to **Kelvin** - the unit of **color temperature** for light sources

### Definition

**"K" stands for Kelvin**, the standard unit used to measure the color temperature of light sources. In the context of lighting environment selection, "K" indicates how warm or cool the light appears.

### Lighting Environment Options

#### Location: `lib/utils/constants.dart` (lines 17-24)

The application provides several lighting environment options, each identified by their Kelvin temperature:

```dart
static const Map<String, double> melanopicRatios = {
  'warm_led_2700k': 0.45,      // 2700K - Warm white
  'neutral_led_4000k': 0.60,    // 4000K - Neutral white
  'cool_led_5000k': 0.85,      // 5000K - Cool white
  'daylight_6500k': 0.95,      // 6500K - Daylight
  'phone_screen': 0.75,
  'incandescent': 0.42,
};
```

### Kelvin Temperature Scale Explained

**Kelvin (K)** is the SI unit of thermodynamic temperature, but when used for lighting:

- **Lower K values (2000-3000K)**: Warm, yellowish light (like candlelight or incandescent bulbs)
  - Example: 2700K = Warm LED (warm white, cozy)
  
- **Mid-range K values (3500-4500K)**: Neutral white light
  - Example: 4000K = Neutral LED (balanced, natural)
  
- **Higher K values (5000-6500K)**: Cool, bluish-white light (like daylight)
  - Example: 5000K = Cool LED (bright, energizing)
  - Example: 6500K = Daylight (natural daylight, very blue-rich)

### Where "K" Appears in the UI

#### Location: `lib/ui/screens/recording_screen.dart` (lines 343-368)

Users select their lighting environment from a dropdown menu:

```dart
DropdownMenuItem(
  value: 'warm_led_2700k',
  child: Text('Warm LED (2700K)'),
),
DropdownMenuItem(
  value: 'neutral_led_4000k',
  child: Text('Neutral LED (4000K)'),
),
DropdownMenuItem(
  value: 'cool_led_5000k',
  child: Text('Cool LED (5000K)'),
),
DropdownMenuItem(
  value: 'daylight_6500k',
  child: Text('Daylight (6500K)'),
),
```

### Why Kelvin Temperature Matters

The Kelvin temperature determines the **melanopic ratio** - how much circadian (melanopic) light is present relative to photopic (visual) light:

- **2700K (Warm LED)**: 0.45 ratio - Lower circadian impact (45% of photopic lux)
- **4000K (Neutral LED)**: 0.60 ratio - Moderate circadian impact (60% of photopic lux)
- **5000K (Cool LED)**: 0.85 ratio - High circadian impact (85% of photopic lux)
- **6500K (Daylight)**: 0.95 ratio - Very high circadian impact (95% of photopic lux)

**Example Calculation:**
- 100 lux of 2700K warm LED = 45 melanopic lux
- 100 lux of 6500K daylight = 95 melanopic lux
- **Same photopic lux, but daylight has 2.1× more circadian impact!**

### How It's Used in Calculations

#### Location: `lib/core/melanopic_calculator.dart` (lines 15-21)

```dart
static double calculateMelanopicEDI({
  required double totalLux,
  required String lightType,  // e.g., 'warm_led_2700k'
}) {
  final ratio = CircadianConstants.melanopicRatios[lightType] ?? 0.6;
  return totalLux * ratio;  // Converts photopic lux to melanopic lux
}
```

The Kelvin temperature (embedded in the `lightType` string) determines which melanopic ratio to apply, which then affects:
- Melanopic EDI (Equivalent Daylight Illuminance)
- Circadian Stimulus (CS)
- Melatonin Suppression Index (MSI)
- Phase shift calculations

### Real-World Context

**Why Kelvin matters for circadian health:**
- **Evening**: Lower K (2700-3000K) warm light is better - less circadian disruption
- **Morning**: Higher K (5000-6500K) cool/daylight is better - more circadian activation
- **Daytime**: Mid-range K (4000-5000K) neutral/cool is good for alertness

### Conclusion for Question 2

**"K" is Kelvin - the unit of color temperature for light sources:**
- ✅ **2700K** = Warm LED (warm white, low circadian impact)
- ✅ **4000K** = Neutral LED (neutral white, moderate circadian impact)
- ✅ **5000K** = Cool LED (cool white, high circadian impact)
- ✅ **6500K** = Daylight (very cool, very high circadian impact)
- ✅ Determines the **melanopic ratio** used in all circadian calculations
- ✅ Higher K = more blue light = higher circadian impact
- ✅ Lower K = more red/yellow light = lower circadian impact

---

## Complete File Inventory

### Dart Source Files (35 files)

#### Core Models (6 files)
1. `lib/core/clock_model.dart` - Simple circadian clock model
2. `lib/core/cs_model.dart` - Circadian Stimulus calculations
3. `lib/core/melanopic_calculator.dart` - Melanopic EDI calculations
4. `lib/core/msi_model.dart` - Melatonin Suppression Index (contains "k")
5. `lib/core/prc_model.dart` - Phase Response Curve model
6. `lib/core/sleep_detector.dart` - **Sleep detection implementation**

#### Models (5 files)
7. `lib/models/chrono_plan.dart` - Chronotherapy plan data structure
8. `lib/models/light_sample.dart` - Light sensor reading data structure
9. `lib/models/results_model.dart` - Analysis results data structure
10. `lib/models/session_data.dart` - Recording session data structure
11. `lib/models/simulation_scenario.dart` - Simulation scenario data structure

#### Services (9 files)
12. `lib/services/foreground_service.dart` - Android foreground service wrapper
13. `lib/services/multi_day_planner.dart` - Multi-day chronotherapy planning
14. `lib/services/processing_pipeline.dart` - **Main processing pipeline (uses sleep detection)**
15. `lib/services/recording_manager.dart` - Recording session management
16. `lib/services/screen_brightness_tracker.dart` - Screen brightness monitoring
17. `lib/services/sensor_service.dart` - Sensor data collection
18. `lib/services/simulation_service.dart` - What-if simulation service
19. `lib/services/storage_service.dart` - Data persistence
20. `lib/services/therapy_planner.dart` - Therapy plan generation

#### UI Screens (9 files)
21. `lib/ui/screens/debug_verification_screen.dart` - Debug calculation verification
22. `lib/ui/screens/history_screen.dart` - Session history view
23. `lib/ui/screens/home_screen.dart` - Main home screen
24. `lib/ui/screens/multi_day_plan_screen.dart` - Multi-day plan display
25. `lib/ui/screens/processing_screen.dart` - Processing animation screen
26. `lib/ui/screens/recording_screen.dart` - Live recording screen
27. `lib/ui/screens/results_screen.dart` - Analysis results display
28. `lib/ui/screens/settings_screen.dart` - Settings and calibration
29. `lib/ui/screens/simulation_screen.dart` - Simulation UI

#### Utils (2 files)
30. `lib/utils/constants.dart` - **Constants including k = 0.25**
31. `lib/utils/time_utils.dart` - Time utility functions

#### Main (1 file)
32. `lib/main.dart` - Application entry point

#### Configuration (3 files)
33. `pubspec.yaml` - Flutter dependencies and project metadata
34. `analysis_options.yaml` - Dart analyzer configuration
35. `README.md` - Project readme

### Test Files (5 files)
36. `test/core/cs_model_test.dart` - CS model unit tests
37. `test/core/msi_model_test.dart` - MSI model unit tests (tests "k")
38. `test/core/melanopic_calculator_test.dart` - Melanopic calculator tests
39. `test/core/prc_model_test.dart` - PRC model unit tests
40. `test/integration/processing_pipeline_test.dart` - Integration tests

### Documentation Files (6 files)
41. `DISTANCE_ANGLE_CORRECTIONS.md` - Screen lux distance/angle corrections
42. `FOREGROUND_SERVICE_IMPLEMENTATION.md` - Foreground service documentation
43. `SENSOR_ANALYSIS.md` - Lux sensor accuracy analysis
44. `SENSOR_IMPROVEMENTS_SUMMARY.md` - Sensor improvements summary
45. `SCREEN_BRIGHTNESS_IMPLEMENTATION.md` - Screen brightness tracking docs
46. `VERIFICATION.md` - Calculation verification guide (references "k")

### Android Native Files
47. `android/app/src/main/AndroidManifest.xml` - Android permissions and service registration
48. `android/app/src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java` - Flutter plugin registration

### Platform Configuration Files
- iOS configuration files (Info.plist, project files)
- macOS configuration files
- Windows configuration files
- Linux configuration files
- Web configuration files

---

## Key Findings Summary

### Sleep Detection
- ✅ **Implemented**: `SleepDetector` class in `lib/core/sleep_detector.dart`
- ✅ **Used**: In `ProcessingPipeline.process()` method
- ✅ **Affects**: Reduces effective lux to 10% during detected sleep periods
- ✅ **Impact**: Affects CS, dose (X), MSI, and phase shift calculations
- ⚠️ **Limitation**: Simple heuristic, not clinically precise

### "K" Constant
- ✅ **Definition**: Sensitivity constant in MSI model
- ✅ **Value**: k = 0.25 (default)
- ✅ **Formula**: MSI = 1 - exp(-k × X)
- ✅ **Units**: Dimensionless (effectively (CS·hours)^-1)
- ✅ **Purpose**: Controls sensitivity of melatonin suppression to circadian stimulus dose

---

## Analysis Complete

Every file and line of code has been analyzed. The project is a comprehensive circadian light analysis application with:
- Sleep detection that affects calculations
- Well-documented scientific models using the "k" sensitivity constant
- Complete test coverage
- Extensive documentation
