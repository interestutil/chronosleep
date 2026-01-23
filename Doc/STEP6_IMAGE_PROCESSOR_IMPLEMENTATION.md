# Step 6: Image Processor Implementation

**Developer B - Completed**

## Overview

Step 6 implements the image processor for extracting RGB values from camera images. This service processes camera images, samples multiple regions, filters for neutral/white areas, and calculates weighted average RGB values. It is designed to work independently with a temporary RGB class that will be replaced by Developer A's RGB class in Step 7.

## Files Created

### 1. `lib/services/image_processor.dart`
Main image processor implementation with the following features:

- **Image Decoding**: Decodes JPEG images from camera
- **Multi-Region Sampling**: Samples multiple regions (default: 9 regions in 3x3 grid)
- **Neutral Region Detection**: Identifies and weights neutral/white regions more heavily
- **Weighted Average Calculation**: Calculates weighted average RGB from sampled regions
- **Error Handling**: Comprehensive error handling with fallback strategies
- **Region Extraction**: Utility method for extracting RGB from specific image regions
- **Camera Integration**: Convenience method for processing `CameraImageResult` from Step 5

### 2. `test/services/image_processor_test.dart`
Comprehensive unit tests covering:
- RGB class functionality
- Invalid image handling
- Valid image processing
- Colored image processing
- Region extraction
- Custom parameters
- Metadata validation

## Dependencies Added

### `pubspec.yaml`
- Added `image: ^4.5.4` package for image decoding and processing

## Key Classes

### `RGB` (Temporary)
Temporary RGB class matching Developer A's interface:
- `r`, `g`, `b`: Normalized color values (0.0-1.0)
- Will be replaced with Developer A's RGB class in Step 7

### `RGBExtractionResult`
Result class containing:
- `rgb`: Extracted RGB values
- `sampleCount`: Number of regions sampled
- `neutralRegionRatio`: Ratio of neutral regions found (0.0-1.0)
- `error`: Error message if extraction failed
- `isValid`: Boolean indicating if extraction was successful

### `ImageProcessor`
Main processor class with static methods:

```dart
// Extract average RGB from image
static RGBExtractionResult extractAverageRGB(
  Uint8List imageBytes, {
  int sampleRegions = 9,
  double neutralThreshold = 0.15,
})

// Extract RGB from specific region
static RGBExtractionResult extractRGBFromRegion(
  Uint8List imageBytes, {
  required int x,
  required int y,
  required int width,
  required int height,
})

// Convenience method for CameraImageResult
static RGBExtractionResult extractRGBFromCameraImage(
  CameraImageResult cameraResult, {
  int sampleRegions = 9,
  double neutralThreshold = 0.15,
})
```

## Algorithm Details

### Multi-Region Sampling Strategy

1. **Edge Avoidance**: Samples regions avoiding 10% margins on all sides
2. **Grid Layout**: Arranges sample regions in a square grid (e.g., 3x3 for 9 regions)
3. **Region Averaging**: Calculates average RGB for each region
4. **Neutral Detection**: Identifies regions where R, G, B values are similar (within threshold)
5. **Weighted Average**: Weights neutral regions 2x more than non-neutral regions
6. **Fallback**: Uses center pixel if no valid samples found

### Neutral Region Detection

A region is considered "neutral" if the maximum difference between R, G, and B values is less than the threshold (default: 0.15). Neutral regions are weighted more heavily because they better represent the actual lighting color temperature (white/neutral surfaces reflect the true color of the light source).

## Usage Example

```dart
// From CameraImageResult (Step 5)
final cameraResult = await detector.captureImage();
if (cameraResult != null) {
  // Extract RGB using convenience method
  final result = ImageProcessor.extractRGBFromCameraImage(cameraResult);
  
  if (result.isValid) {
    print('Extracted RGB: ${result.rgb}');
    print('Sample count: ${result.sampleCount}');
    print('Neutral regions: ${(result.neutralRegionRatio * 100).toStringAsFixed(1)}%');
    
    // Use result.rgb for color conversion (Step 7)
  }
}

// Or directly from image bytes
final imageBytes = ...; // JPEG bytes
final result = ImageProcessor.extractAverageRGB(
  imageBytes,
  sampleRegions: 16, // 4x4 grid
  neutralThreshold: 0.1, // Stricter threshold
);
```

## Integration Points

### For Step 5 (Camera Service)
- Uses `CameraImageResult.imageBytes` as input
- `extractRGBFromCameraImage()` provides convenient integration

### For Step 7 (Main Detector Service)
- Returns `RGB` objects that will be replaced with Developer A's RGB class
- The interface matches Developer A's expected RGB structure

## Testing

All unit tests pass successfully:
- ✅ RGB class basic functionality
- ✅ Invalid image handling
- ✅ Valid image processing (white image)
- ✅ Colored image processing (red image)
- ✅ Region extraction (left/right regions)
- ✅ Invalid region handling
- ✅ Custom parameters
- ✅ Metadata validation

## Performance Considerations

- Uses medium resolution images from camera (Step 5)
- Samples 9 regions by default (configurable)
- Processes regions sequentially (acceptable for mobile)
- JPEG decoding is efficient with the `image` package
- Weighted averaging is O(n) where n is number of regions

## Next Steps

1. **Step 7**: Main detector service will integrate:
   - Camera service (Step 5)
   - Image processor (Step 6)
   - Developer A's color conversion code
   - Mock/stub color conversion for independent development

2. **Step 8**: UI integration will use the detector service

## Notes

- RGB values are normalized to 0.0-1.0 range (standard for color science)
- Neutral threshold of 0.15 is a good default (can be tuned)
- Sample regions default to 9 (3x3 grid) for balance between accuracy and performance
- Edge margins of 10% avoid camera vignetting and edge artifacts
- Fallback to center pixel ensures robustness
- All errors are logged with detailed messages for debugging
- Service is designed to be independent and testable
