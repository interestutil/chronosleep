# Lux Sensor Accuracy and Sensitivity Analysis

## Executive Summary

After analyzing the entire codebase, the lux sensor implementation has **moderate accuracy concerns** and **potentially suboptimal sensitivity settings**. The current smoothing factor of 0.7 may be appropriate, but several improvements are needed for better accuracy and reliability.

## Current Implementation Analysis

### 1. Sensor Data Flow

```
Android Light Sensor (hardware)
  ↓
light package (lightSensorStream)
  ↓
SensorService._luxSubscription (raw lux value)
  ↓
EMA Smoothing (if enabled, factor = 0.7)
  ↓
LightSample.ambientLux
  ↓
MelanopicCalculator.calculateTotalLuxAtEye()
  ↓
Processing Pipeline (CS, MSI, Phase calculations)
```

### 2. Smoothing Implementation

**Current Settings:**
- **Enabled by default**: `sensorSmoothingEnabled = true`
- **Smoothing factor**: `sensorSmoothingFactor = 0.7` (70% weight on new value, 30% on old)
- **Formula**: `smoothed = 0.7 * raw + 0.3 * old_smoothed`

**Analysis:**
- ✅ **Correctly implemented**: The EMA formula is mathematically sound
- ⚠️ **Factor 0.7 is quite responsive**: This means 70% of each new reading immediately affects the smoothed value
- ⚠️ **User feedback history**: 
  - Factor 0.3 was "too insensitive"
  - Factor 0.7 might be appropriate, but could still show fluctuations

### 3. Accuracy Issues Identified

#### ❌ **No Sensor Calibration**
- Raw sensor values are used directly without device-specific calibration
- Different Android devices have varying sensor characteristics:
  - Accuracy: ±10-20% is common for phone light sensors
  - Range: Some sensors cap at lower values (e.g., 10,000 lux max)
  - Response time: Varies by device
  - Spectral sensitivity: Most phone sensors are photopic (not melanopic), which is handled correctly by applying melanopic ratios

#### ❌ **No Range Validation**
- No validation that sensor readings are within reasonable bounds
- Could accept negative values (should be clamped to 0)
- Could accept unrealistic high values (should be capped at `maxSafeLux = 10000.0`)
- No check for NaN or infinity values

#### ❌ **No Outlier Detection**
- Sudden spikes or drops in sensor readings aren't filtered
- Could be caused by:
  - Sensor noise
  - Temporary obstructions (hand covering sensor)
  - Device movement causing rapid light changes

#### ❌ **No Sampling Rate Control**
- Sensor emits values at hardware rate (could be 10-100+ Hz)
- All values are captured and processed, which could lead to:
  - Excessive data storage
  - Unnecessary processing overhead
  - Potential smoothing issues if readings come too fast

#### ⚠️ **EMA Initialization**
- First reading initializes smoothed value directly
- This is correct, but if first reading is an outlier, it affects subsequent readings

### 4. Sensitivity Analysis

**Current Factor 0.7:**
- **Response to step change**: Takes ~3-4 samples to reach 90% of new value
- **Noise reduction**: Moderate (reduces high-frequency noise but allows rapid changes)
- **Lag**: Minimal (responds quickly to real changes)

**Comparison:**
- **Factor 0.3** (previous): Too much smoothing, slow response, "too insensitive"
- **Factor 0.7** (current): Good balance, but may still show some fluctuations
- **Factor 1.0** (no smoothing): Raw sensor readings, maximum fluctuations

**Recommendation**: Factor 0.7 is reasonable, but consider:
- Adding outlier detection before smoothing
- Implementing adaptive smoothing (higher factor for stable conditions, lower for noisy conditions)
- Adding a dead-band filter for very small changes

## Recommendations

### Priority 1: Critical Accuracy Improvements

1. **Add Range Validation**
   ```dart
   // In SensorService, after reading raw lux:
   final rawLux = luxVal.toDouble();
   final clampedLux = rawLux.clamp(0.0, CircadianConstants.maxSafeLux);
   if (rawLux != clampedLux) {
     debugPrint('Warning: Lux value $rawLux clamped to $clampedLux');
   }
   ```

2. **Add Outlier Detection**
   ```dart
   // Reject readings that differ by more than X% from smoothed value
   if (_smoothedLux != null) {
     final percentChange = (rawLux - _smoothedLux!).abs() / (_smoothedLux! + 1.0);
     if (percentChange > 0.5) { // 50% change threshold
       // Possible outlier, use weighted average or skip
     }
   }
   ```

3. **Add NaN/Infinity Checks**
   ```dart
   if (!rawLux.isFinite || rawLux.isNaN) {
     debugPrint('Warning: Invalid lux reading: $rawLux');
     return; // Skip this reading
   }
   ```

### Priority 2: Sensitivity Optimization

1. **Consider Adaptive Smoothing**
   - Use higher factor (0.8-0.9) when readings are stable
   - Use lower factor (0.5-0.6) when readings are fluctuating rapidly
   - This provides best of both worlds: responsive to real changes, stable during noise

2. **Add Dead-Band Filter**
   - Ignore changes smaller than a threshold (e.g., 1-2 lux)
   - Prevents micro-fluctuations from affecting smoothed value
   - Useful for low-light conditions where sensor noise is more apparent

3. **Consider Median Filter for Outlier Removal**
   - Keep last N readings (e.g., 5)
   - Use median instead of mean for outlier-resistant smoothing
   - More robust to temporary spikes

### Priority 3: Calibration and Device-Specific Adjustments

1. **Add Calibration Offset**
   - Allow users to calibrate against a known reference
   - Store device-specific calibration factor
   - Apply: `calibratedLux = rawLux * calibrationFactor`

2. **Device-Specific Defaults**
   - Research common sensor characteristics by device model
   - Apply default calibration factors for known devices
   - Document in settings screen

### Priority 4: Performance and Data Quality

1. **Implement Sampling Rate Limiting**
   - Throttle sensor readings to reasonable rate (e.g., 1-10 Hz)
   - Prevents excessive data collection
   - Reduces processing overhead

2. **Add Sensor Health Monitoring**
   - Track sensor reading frequency
   - Detect sensor failures (no readings for extended period)
   - Warn user if sensor appears unreliable

## Code Locations for Implementation

1. **SensorService** (`lib/services/sensor_service.dart`):
   - Lines 32-50: Sensor reading and smoothing logic
   - Add validation and outlier detection here

2. **Constants** (`lib/utils/constants.dart`):
   - Lines 41-43: Smoothing settings
   - Add new constants for validation thresholds

3. **Settings Screen** (`lib/ui/screens/settings_screen.dart`):
   - Lines 147-219: Smoothing configuration UI
   - Could add calibration UI here

## Testing Recommendations

1. **Static Light Test**: Place device under constant light source, verify readings are stable
2. **Step Response Test**: Rapidly change light conditions, verify smoothing responds appropriately
3. **Outlier Test**: Temporarily cover sensor, verify system handles it gracefully
4. **Range Test**: Test with very bright light (if possible), verify clamping works
5. **Comparison Test**: Compare readings with calibrated lux meter

## Conclusion

**Current Status**: The sensor implementation is **functionally correct** but has **accuracy and reliability gaps**. The smoothing factor of 0.7 is a reasonable default, but the system would benefit from:

1. ✅ **Immediate**: Range validation and NaN checks (critical for reliability)
2. ✅ **Short-term**: Outlier detection and dead-band filtering (improves accuracy)
3. ✅ **Medium-term**: Adaptive smoothing and calibration support (enhances user experience)

**Sensitivity Assessment**: The current factor of 0.7 is **likely appropriate** for most use cases, but adding outlier detection and dead-band filtering would make it more robust without requiring factor adjustment.

**Accuracy Assessment**: The sensor readings are **reasonably accurate** for consumer-grade phone sensors (±10-20% typical), but lack of validation and calibration means accuracy could be improved with the recommended changes.

