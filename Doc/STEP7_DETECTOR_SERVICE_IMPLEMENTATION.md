# Step 7: Main Detector Service Implementation

**Developer B - Completed**

## Overview

Step 7 implements the main lighting environment detector service that integrates camera-based detection (CIE xy) with heuristic fallback. This service uses mock color conversion functions that will be replaced with Developer A's real implementations in Step 9.

## Files Created

### 1. `lib/services/lighting_environment_detector.dart`
Main detector service with the following features:

- **Camera Integration**: Uses camera service (Step 5) for image capture
- **Image Processing**: Uses image processor (Step 6) for RGB extraction
- **Mock Color Conversion**: Uses mock color conversion (temporary, will be replaced in Step 9)
- **Heuristic Fallback**: Time + lux-based detection when camera unavailable
- **Auto-Detection**: Automatically chooses best available method
- **Confidence Calculation**: Provides confidence scores for all detections
- **Screen Detection**: Detects screen-dominant lighting scenarios

### 2. `lib/services/mocks/color_conversion_mock.dart`
Mock color conversion functions:

- **RGB → xy**: Simple approximation based on R/B ratio
- **xy → CCT**: Linear approximation for color temperature
- **D_uv Calculation**: Placeholder (returns medium confidence)
- **CCT → Light Type**: Maps Kelvin to light type constants
- **Confidence Calculation**: Based on D_uv, CCT range, and neutral regions

### 3. `test/services/lighting_environment_detector_test.dart`
Comprehensive unit tests covering:
- Heuristic detection (evening, morning, daytime)
- Screen-dominant detection
- Mock color conversion
- Result serialization
- All tests passing ✅

## Key Classes

### `LightingEnvironmentDetector`
Main service class with the following API:

```dart
// Initialize detector
Future<bool> initialize()

// Camera-based detection
Future<LightingDetectionResult?> detectWithCamera()

// Heuristic-based detection
LightingDetectionResult detectWithHeuristics({
  required DateTime time,
  required double currentLux,
  required List<LightSample> recentSamples,
  double? screenBrightness,
})

// Auto-detect (tries camera first, falls back to heuristics)
Future<LightingDetectionResult> autoDetect({
  required DateTime time,
  required double currentLux,
  required List<LightSample> recentSamples,
  double? screenBrightness,
  bool preferCamera = true,
})

// Get camera preview widget
Widget? getCameraPreview()

// Cleanup
Future<void> dispose()
```

### `LightingDetectionResult`
Result class containing:
- `lightType`: String (e.g., 'warm_led_2700k', 'daylight_6500k')
- `kelvin`: Double? (color temperature, null for heuristic method)
- `confidence`: Double (0.0-1.0)
- `method`: String ('cie_xy' or 'heuristic')
- `chromaticity`: MockChromaticity? (only for CIE xy method)
- `duv`: Double? (only for CIE xy method)

### `MockColorConverter`
Mock color conversion functions (temporary):
- `rgbToChromaticity()`: RGB → xy approximation
- `chromaticityToCCT()`: xy → CCT approximation
- `calculateDUV()`: D_uv placeholder
- `cctToLightType()`: CCT → light type mapping
- `calculateConfidence()`: Confidence calculation

## Detection Pipeline

### Camera-Based Detection (CIE xy)

1. **Capture Image**: Uses camera service to capture image
2. **Extract RGB**: Uses image processor to extract RGB values
3. **RGB → xy**: Convert RGB to chromaticity (mock)
4. **xy → CCT**: Convert chromaticity to color temperature (mock)
5. **Calculate D_uv**: Distance from Planckian locus (mock)
6. **Map to Light Type**: CCT → light type string
7. **Calculate Confidence**: Based on D_uv, CCT, and neutral regions

### Heuristic Detection (Fallback)

1. **Screen Detection**: Check if screen is dominant (>70% of light)
2. **Time-Based Logic**: Use time of day to narrow possibilities
3. **Lux-Based Logic**: Use current lux level to refine estimate
4. **Return Result**: Light type + confidence score

### Auto-Detection Strategy

1. Try camera-based detection if available and preferred
2. If camera fails or confidence < 0.5, fall back to heuristics
3. Return best available result

## Heuristic Rules

### Evening/Night (7 PM - 6 AM)
- Low lux (<50): Warm LED (2700K) - 70% confidence
- Medium lux (50-200): Neutral LED (4000K) - 60% confidence
- High lux (>200): Cool LED (5000K) - 50% confidence

### Morning (6-10 AM)
- High lux (>1000): Daylight (6500K) - 80% confidence
- Medium lux (500-1000): Cool LED (5000K) - 70% confidence
- Low lux (<500): Neutral LED (4000K) - 60% confidence

### Daytime (10 AM - 7 PM)
- High lux (>1000): Daylight (6500K) - 80% confidence
- Medium-high lux (500-1000): Cool LED (5000K) - 70% confidence
- Medium lux (200-500): Neutral LED (4000K) - 60% confidence
- Low lux (<200): Warm LED (2700K) - 60% confidence

### Screen-Dominant
- Screen brightness > 0.5 AND screen lux > 70% of total lux
- Returns 'phone_screen' with 70% confidence

## Usage Example

```dart
// Initialize detector
final detector = LightingEnvironmentDetector();
await detector.initialize();

// Auto-detect (tries camera first, falls back to heuristics)
final result = await detector.autoDetect(
  time: DateTime.now(),
  currentLux: 500.0,
  recentSamples: samples,
  screenBrightness: 0.3,
  preferCamera: true,
);

print('Detected: ${result.lightType}');
print('Confidence: ${(result.confidence * 100).toStringAsFixed(1)}%');
print('Method: ${result.method}');

// Or use specific method
final cameraResult = await detector.detectWithCamera();
final heuristicResult = detector.detectWithHeuristics(
  time: DateTime.now(),
  currentLux: 500.0,
  recentSamples: samples,
);

// Cleanup
await detector.dispose();
```

## Integration Points

### For Step 5 (Camera Service)
- Uses `CameraColorDetector` for image capture
- Gets camera preview widget for UI

### For Step 6 (Image Processor)
- Uses `ImageProcessor.extractRGBFromCameraImage()` for RGB extraction
- Uses neutral region ratio for confidence calculation

### For Step 8 (UI Integration)
- Provides `autoDetect()` for easy UI integration
- Provides `getCameraPreview()` for camera preview widget
- Returns `LightingDetectionResult` with all needed information

### For Step 9 (Integration with Developer A)
- Mock color conversion will be replaced with real implementations
- `MockChromaticity` will be replaced with Developer A's `CIEChromaticity`
- `MockColorConverter` functions will be replaced with real CIE calculations

## Testing

All unit tests pass successfully:
- ✅ Initial state verification
- ✅ Heuristic detection (evening, morning, daytime)
- ✅ Screen-dominant detection
- ✅ Result serialization (toMap, toString)
- ✅ Mock color conversion (RGB → xy, xy → CCT, CCT → light type)
- ✅ Confidence calculation

## Mock Color Conversion Details

### RGB → xy Approximation
- Uses R/B ratio to estimate chromaticity
- High R/B → warm light (higher x, lower y)
- Low R/B → cool light (lower x, higher y)
- Clamped to valid CIE xy range

### xy → CCT Approximation
- Uses x/y ratio for linear approximation
- Rough mapping: ratio > 1.2 → warm, < 0.9 → cool
- Clamped to 2000K-10000K range

### Confidence Calculation
- Base: 1.0 - (D_uv × 10), clamped to 0.5
- Adjusted for extreme CCT values (<2500K or >8000K): ×0.8
- Boosted by neutral region ratio: 70% base + 30% neutral ratio

## Next Steps

1. **Step 8**: UI integration will use this detector service
2. **Step 9**: Replace mock color conversion with Developer A's real implementations

## Notes

- Mock color conversion provides reasonable estimates but is not scientifically accurate
- Real CIE 1931 xy calculations will be much more accurate
- Heuristic fallback ensures detection always works, even without camera
- Confidence scores help UI indicate detection quality
- Screen-dominant detection prevents misclassification when phone screen is main light source
- All methods are well-documented and testable
- Service is designed for easy integration with Developer A's code in Step 9
