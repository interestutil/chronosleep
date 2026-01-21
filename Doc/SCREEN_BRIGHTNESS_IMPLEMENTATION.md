# Screen Brightness Tracking Implementation

## Summary

Screen brightness tracking has been successfully implemented, allowing the application to include screen light contribution in all circadian rhythm calculations.

## What Was Implemented

### 1. **Screen Brightness Package**
- Added `screen_brightness: ^2.1.7` to `pubspec.yaml`
- Provides access to system screen brightness (0.0 to 1.0)

### 2. **ScreenBrightnessTracker Service**
- **Location**: `lib/services/screen_brightness_tracker.dart`
- **Functionality**:
  - Monitors screen brightness every 2 seconds
  - Detects brightness changes (>5% threshold)
  - Detects screen on/off state
  - Updates `SensorService` via `updateScreenState()` method
  - Handles errors gracefully (some devices can't read brightness when screen is off)

### 3. **Integration with RecordingScreen**
- **Location**: `lib/ui/screens/recording_screen.dart`
- **Changes**:
  - Added `WidgetsBindingObserver` to track app lifecycle
  - Creates `ScreenBrightnessTracker` instance
  - Starts tracking when recording starts
  - Stops tracking when recording stops
  - Updates screen state on app lifecycle changes (background/foreground)

### 4. **Display Updates**
- Real-time display now shows **total lux** (ambient + screen contribution)
- CS calculation in display includes screen contribution
- Matches what the processing pipeline calculates

## How It Works

### Data Flow

```
Screen Brightness (System)
  ↓
ScreenBrightnessTracker (reads every 2 seconds)
  ↓
SensorService.updateScreenState()
  ↓
LightSample (screenOn, screenBrightness)
  ↓
MelanopicCalculator.calculateTotalLuxAtEye()
  ↓
Processing Pipeline (CS, MSI, Phase calculations)
```

### Screen Contribution Calculation

1. **Screen Brightness** (0.0 - 1.0) is read from system
2. **Screen Lux** is estimated using `CircadianConstants.screenBrightnessToLux` mapping:
   - 0.0 → 0 lux
   - 0.2 → 40 lux
   - 0.5 → 120 lux
   - 1.0 → 300 lux
   - (interpolated for values in between)

3. **Total Lux** = Ambient Lux + Screen Lux (if screen is on)

4. **Melanopic EDI** = Total Lux × Melanopic Ratio

5. **CS, MSI, Phase Shift** all calculated from melanopic EDI

## Key Features

### ✅ Automatic Tracking
- Brightness is monitored automatically during recording
- No user intervention required
- Updates every 2 seconds

### ✅ Screen On/Off Detection
- Detects when screen turns off (brightness = 0 or read error)
- Handles app going to background/foreground
- Gracefully handles devices that can't read brightness when screen is off

### ✅ Error Handling
- If brightness can't be read, defaults to screen on with unknown brightness
- Logs debug messages for troubleshooting
- Doesn't crash if screen brightness API is unavailable

### ✅ Performance
- Only updates when brightness changes significantly (>5%)
- Minimal battery impact (checks every 2 seconds)
- Efficient polling strategy

## Configuration

Screen brightness to lux mapping can be calibrated in **Settings**:
- Navigate to Settings → Screen Brightness Calibration
- Adjust lux values for each brightness level (0%, 20%, 40%, 50%, 60%, 80%, 100%)
- Changes apply to future recordings

## Testing

To verify screen contribution is working:

1. **Start a recording**
2. **Check debug logs** (if in debug mode):
   ```
   ScreenBrightnessTracker: Screen on, brightness: 50.0%
   ```
3. **Adjust screen brightness** during recording
4. **Check lux values** - should increase/decrease with brightness
5. **View results** - screen contribution should be included in total lux

## Example Calculation

**Scenario**: Ambient light = 50 lux, Screen brightness = 0.5 (50%)

1. **Screen Lux** = 120 lux (from mapping: 0.5 → 120)
2. **Total Lux** = 50 + 120 = 170 lux
3. **Melanopic EDI** (for neutral LED 4000K) = 170 × 0.60 = 102 melanopic lux
4. **CS** = calculated from melanopic EDI
5. **MSI & Phase Shift** = calculated from CS over time

## Files Modified

1. `pubspec.yaml` - Added screen_brightness package
2. `lib/services/screen_brightness_tracker.dart` - New file
3. `lib/ui/screens/recording_screen.dart` - Integrated tracker

## Files Using Screen Contribution

1. `lib/core/melanopic_calculator.dart` - `calculateTotalLuxAtEye()` adds screen lux
2. `lib/services/processing_pipeline.dart` - Uses `calculateTotalLuxAtEye()` for all samples
3. `lib/ui/screens/recording_screen.dart` - Display shows total lux including screen

## Notes

- Screen brightness tracking only works during active recording
- Some devices may not support reading brightness when screen is off
- The 2-second polling interval is a balance between responsiveness and battery usage
- Screen contribution is significant in low-light conditions (can add 40-300 lux)

## Future Enhancements (Optional)

- Add real-time screen brightness display in recording screen
- Allow users to manually override screen brightness
- Add option to disable screen contribution tracking
- Use platform-specific listeners for brightness changes (if available)

