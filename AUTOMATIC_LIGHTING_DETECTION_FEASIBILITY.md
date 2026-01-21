# Automatic Lighting Environment Detection - Feasibility Analysis

## Current State

### What We Have
- **Light Sensor**: Provides **photopic lux** (brightness) only
- **Package**: `light: ^4.1.0` - Standard ambient light sensor
- **Data Available**: Single lux value per reading
- **Limitation**: No color temperature or spectral information

### What We Need
- **Kelvin Color Temperature** (2700K, 4000K, 5000K, 6500K)
- To determine the correct **melanopic ratio** for circadian calculations

---

## Feasibility: Is Automatic Detection Possible?

### ✅ **YES - But with limitations and trade-offs**

There are **four approaches** with varying feasibility:

---

## Option 1: Color Temperature Sensor (Hardware-Dependent)

### How It Works
- Use Android's `AmbientColorTemperatureSensor` (if available)
- Direct hardware reading of color temperature in Kelvin

### Pros
- ✅ **Most accurate** - Direct measurement
- ✅ **Real-time** - Continuous updates
- ✅ **Low battery impact** - Dedicated sensor hardware

### Cons
- ❌ **Not widely available** - Only on high-end Android devices
- ❌ **iOS limitation** - Very limited support (SensorKit framework, newer devices only)
- ❌ **Requires platform-specific code** - Need native Android/iOS implementation
- ❌ **No Flutter package** - Would need custom platform channels

### Implementation Effort
- **High** - Requires native Android/iOS code
- Need to check sensor availability at runtime
- Fallback to manual selection required

### Recommendation
- ⚠️ **Not recommended as primary solution** - Too device-dependent
- Could be added as **optional enhancement** for supported devices

---

## Option 2: CIE 1931 xy Chromaticity Coordinates (Most Scientifically Accurate)

### How It Works
- Capture camera frames or use RGB sensor data
- Convert RGB → CIE XYZ tristimulus values
- Calculate xy chromaticity coordinates: `x = X/(X+Y+Z)`, `y = Y/(X+Y+Z)`
- Map xy coordinates to Correlated Color Temperature (CCT) using algorithms like:
  - **McCamy's formula** (good for 2800-6500K range)
  - **Hernández-Andrés, Lee & Romero (1999)** method (broader range, better accuracy)
- Convert CCT (Kelvin) to lighting environment category

### Pros
- ✅ **Scientifically accurate** - Uses standardized color science (CIE 1931)
- ✅ **More precise than simple RGB** - Accounts for human color perception
- ✅ **Standardized approach** - Industry-standard method for color temperature
- ✅ **Works on both platforms** - Can use camera RGB data
- ✅ **Brightness-independent** - xy coordinates capture color quality regardless of lux
- ✅ **Enables fine-grained detection** - Continuous Kelvin values, not just categories

### Cons
- ❌ **Requires camera or RGB sensor** - Needs color information, not just lux
- ❌ **Privacy concerns** - Camera permission required
- ❌ **Battery impact** - Camera processing is power-intensive
- ❌ **Calibration needed** - Device-specific color profiles may be needed
- ❌ **Off-Planckian sources** - Colored lights (RGB LEDs, fluorescents) may deviate from blackbody locus
- ⚠️ **D_uv consideration** - Need to check distance from Planckian locus for accuracy

### Implementation Approach

```dart
class CIEChromaticityDetector {
  /// Convert RGB to CIE XYZ tristimulus values
  /// (Requires device-specific color matrix or standard sRGB matrix)
  CIEXYZ rgbToXYZ(double r, double g, double b) {
    // Linearize RGB (gamma correction)
    // Apply color matrix transformation
    // Return XYZ values
  }
  
  /// Calculate xy chromaticity coordinates from XYZ
  CIEChromaticity xyzToChromaticity(CIEXYZ xyz) {
    final x = xyz.x / (xyz.x + xyz.y + xyz.z);
    final y = xyz.y / (xyz.x + xyz.y + xyz.z);
    return CIEChromaticity(x: x, y: y);
  }
  
  /// Convert xy to Correlated Color Temperature (Kelvin)
  /// Using McCamy's approximation formula
  double chromaticityToCCT(CIEChromaticity xy) {
    final n = (xy.x - 0.3320) / (0.1858 - xy.y);
    final cct = 437 * pow(n, 3) + 3601 * pow(n, 2) + 6861 * n + 5517;
    return cct;
  }
  
  /// Map CCT (Kelvin) to lighting environment category
  String cctToLightType(double kelvin) {
    if (kelvin < 3000) return 'warm_led_2700k';
    if (kelvin < 4500) return 'neutral_led_4000k';
    if (kelvin < 6000) return 'cool_led_5000k';
    return 'daylight_6500k';
  }
}
```

### Scientific Foundation

**CIE 1931 Color Space:**
- Standardized color matching functions based on human color perception
- xy coordinates are brightness-independent (capture color quality)
- Planckian locus represents blackbody radiators (natural light sources)

**McCamy's Formula:**
```
n = (x - 0.3320) / (0.1858 - y)
CCT ≈ 437n³ + 3601n² + 6861n + 5517
```
- Works well for 2800-6500K range
- Accuracy: ±50-200K for typical lighting

**Hernández-Andrés Method:**
- More accurate, broader range (2000-20000K)
- Better handling of off-Planckian sources

### Implementation Effort
- **Medium-High** - Requires:
  - Camera permission handling
  - RGB → XYZ conversion (color matrix)
  - XYZ → xy calculation
  - xy → CCT algorithm (McCamy or Hernández-Andrés)
  - CCT → light type mapping
  - D_uv calculation for quality assessment
  - Fallback handling

### Recommendation
- ✅ **RECOMMENDED for accuracy** - Most scientifically sound approach
- Best combined with Option 3 (heuristics) for fallback
- Could offer as **"Detect with Camera (CIE)"** option
- More accurate than simple RGB estimation

---

## Option 3: Simple Camera-Based RGB Estimation

### How It Works
- Capture camera frames periodically
- Extract average RGB values from image
- Use simple RGB ratios to estimate color temperature
- Less sophisticated than CIE xy method

### Pros
- ✅ **Simpler than CIE xy** - Easier to implement
- ✅ **Widely available** - Camera on all smartphones
- ✅ **Works on both platforms** - Android and iOS

### Cons
- ❌ **Less accurate** - Doesn't account for human color perception
- ❌ **Privacy concerns** - Requires camera permission
- ❌ **Battery impact** - Camera processing is power-intensive
- ❌ **Affected by camera settings** - White balance, exposure compensation
- ❌ **Subject-dependent** - May measure scene colors, not just ambient light

### Implementation Effort
- **Medium** - Simpler than CIE xy but less accurate

### Recommendation
- ⚠️ **Use Option 2 (CIE xy) instead** - More accurate and scientifically sound

---

## Option 4: Heuristic-Based Estimation (Recommended Fallback)

### How It Works
- Use **time of day** + **lux level** + **lux patterns** to estimate lighting environment
- Apply rules based on typical lighting scenarios

### Pros
- ✅ **No additional permissions** - Uses existing sensor data
- ✅ **Low battery impact** - No camera or extra sensors
- ✅ **Works everywhere** - Uses data we already collect
- ✅ **Simple to implement** - Pure Dart logic

### Cons
- ⚠️ **Less accurate** - Estimates based on patterns, not direct measurement
- ⚠️ **Context-dependent** - Assumes typical usage patterns

### Implementation Approach

```dart
class LightingEnvironmentDetector {
  /// Estimate lighting environment from time of day and lux patterns
  String estimateLightType({
    required DateTime time,
    required double currentLux,
    required List<double> recentLuxHistory, // Last 5-10 minutes
  }) {
    final hour = time.hour;
    
    // Morning (6-10 AM): Likely daylight or cool LED
    if (hour >= 6 && hour < 10) {
      if (currentLux > 500) return 'daylight_6500k';
      if (currentLux > 200) return 'cool_led_5000k';
      return 'neutral_led_4000k';
    }
    
    // Evening (7 PM - 11 PM): Likely warm LED
    if (hour >= 19 || hour < 23) {
      if (currentLux < 100) return 'warm_led_2700k';
      return 'neutral_led_4000k';
    }
    
    // Night (11 PM - 6 AM): Very likely warm/dim
    if (hour >= 23 || hour < 6) {
      return 'warm_led_2700k';
    }
    
    // Daytime (10 AM - 7 PM): Likely neutral or cool
    if (currentLux > 1000) return 'daylight_6500k';
    if (currentLux > 500) return 'cool_led_5000k';
    return 'neutral_led_4000k';
  }
}
```

### Enhanced Heuristic (More Accurate)

```dart
class AdvancedLightingDetector {
  String detectLightType({
    required DateTime time,
    required double currentLux,
    required List<double> luxHistory,
    required double? screenBrightness,
  }) {
    final hour = time.hour;
    
    // Check if screen is dominant light source
    if (screenBrightness != null && screenBrightness > 0.5) {
      final screenLux = estimateScreenLux(screenBrightness);
      if (screenLux > currentLux * 0.7) {
        return 'phone_screen'; // Screen is dominant
      }
    }
    
    // Very low lux (< 20) = likely warm/dim
    if (currentLux < 20) {
      return hour >= 19 || hour < 6 ? 'warm_led_2700k' : 'neutral_led_4000k';
    }
    
    // Very high lux (> 1000) = likely daylight
    if (currentLux > 1000) {
      return 'daylight_6500k';
    }
    
    // Check lux stability (indoor vs outdoor)
    final luxVariance = calculateVariance(luxHistory);
    if (luxVariance < 50) {
      // Stable = indoor lighting
      return hour >= 19 || hour < 6 ? 'warm_led_2700k' : 'neutral_led_4000k';
    } else {
      // Variable = outdoor/daylight
      return 'daylight_6500k';
    }
    
    // Default based on time
    return hour >= 19 || hour < 6 ? 'warm_led_2700k' : 'neutral_led_4000k';
  }
}
```

### Implementation Effort
- **Low-Medium** - Pure Dart implementation
- Can be added incrementally
- Easy to test and refine

### Recommendation
- ✅ **RECOMMENDED** - Best balance of accuracy and feasibility
- Can be combined with manual selection (auto-detect + allow override)

---

## Recommended Implementation Strategy

### Phase 1: Heuristic Auto-Detection (Immediate)
1. Implement time-of-day + lux-based estimation
2. Show detected lighting type with option to override
3. Learn from user corrections to improve accuracy

### Phase 2: CIE xy Chromaticity Detection (Enhanced Accuracy)
1. Add camera-based CIE 1931 xy detection as optional feature
2. Implement RGB → XYZ → xy → CCT pipeline
3. Use McCamy's or Hernández-Andrés formula for CCT calculation
4. Combine with heuristics for fallback when camera unavailable
5. Show confidence based on D_uv (distance from Planckian locus)

### Phase 3: Hardware Support (If Available)
1. Add color temperature sensor support for devices that have it
2. Use as primary source when available
3. Fall back to CIE xy or heuristics otherwise

---

## Implementation Examples

### Example 1: CIE 1931 xy Chromaticity Detection

#### New Service: `lib/services/cie_chromaticity_detector.dart`

```dart
import 'dart:math';
import 'package:camera/camera.dart'; // Would need to add camera package
import '../utils/constants.dart';

/// CIE 1931 xy chromaticity coordinates
class CIEChromaticity {
  final double x;
  final double y;
  
  CIEChromaticity({required this.x, required this.y});
  
  /// Calculate distance from Planckian locus (D_uv)
  /// Lower D_uv = closer to blackbody radiator = more accurate CCT
  double distanceFromPlanckianLocus() {
    // Simplified: calculate distance from nearest point on Planckian locus
    // Full implementation would require lookup table or iterative calculation
    return 0.0; // Placeholder
  }
}

/// CIE XYZ tristimulus values
class CIEXYZ {
  final double x;
  final double y;
  final double z;
  
  CIEXYZ({required this.x, required this.y, required this.z});
}

class CIEChromaticityDetector {
  /// Convert linear RGB to CIE XYZ using sRGB color matrix
  /// Note: Requires linearized RGB (gamma correction applied)
  static CIEXYZ rgbToXYZ(double r, double g, double b) {
    // sRGB to XYZ transformation matrix (D65 illuminant)
    // This is a simplified version - full implementation would use device-specific profiles
    final x = 0.4124564 * r + 0.3575761 * g + 0.1804375 * b;
    final y = 0.2126729 * r + 0.7151522 * g + 0.0721750 * b;
    final z = 0.0193339 * r + 0.1191920 * g + 0.9503041 * b;
    
    return CIEXYZ(x: x, y: y, z: z);
  }
  
  /// Calculate xy chromaticity coordinates from XYZ
  static CIEChromaticity xyzToChromaticity(CIEXYZ xyz) {
    final sum = xyz.x + xyz.y + xyz.z;
    if (sum == 0) {
      // Avoid division by zero
      return CIEChromaticity(x: 0.3127, y: 0.3290); // D65 white point
    }
    
    final x = xyz.x / sum;
    final y = xyz.y / sum;
    
    return CIEChromaticity(x: x, y: y);
  }
  
  /// Convert xy chromaticity to Correlated Color Temperature (CCT) in Kelvin
  /// Using McCamy's approximation formula
  /// Range: ~2800K to ~6500K (good accuracy)
  static double chromaticityToCCT(CIEChromaticity xy) {
    // McCamy's formula
    final n = (xy.x - 0.3320) / (0.1858 - xy.y);
    
    // Avoid invalid values
    if (!n.isFinite || n.isNaN) {
      return 4000.0; // Default neutral
    }
    
    final cct = 437 * pow(n, 3) + 3601 * pow(n, 2) + 6861 * n + 5517;
    
    // Clamp to reasonable range
    return cct.clamp(2000.0, 20000.0);
  }
  
  /// Alternative: Hernández-Andrés, Lee & Romero (1999) method
  /// More accurate, broader range (2000-20000K)
  static double chromaticityToCCT_Hernandez(CIEChromaticity xy) {
    final xe = 0.3320;
    final ye = 0.1858;
    
    final n = (xy.x - xe) / (xy.y - ye);
    
    if (!n.isFinite || n.isNaN) {
      return 4000.0;
    }
    
    // Hernández-Andrés formula (more accurate)
    final cct = 449 * pow(n, 3) + 3525 * pow(n, 2) + 6823.3 * n + 5520.33;
    
    return cct.clamp(2000.0, 20000.0);
  }
  
  /// Map CCT (Kelvin) to lighting environment category
  static String cctToLightType(double kelvin) {
    if (kelvin < 3000) {
      return 'warm_led_2700k';
    } else if (kelvin < 4500) {
      return 'neutral_led_4000k';
    } else if (kelvin < 6000) {
      return 'cool_led_5000k';
    } else {
      return 'daylight_6500k';
    }
  }
  
  /// Detect lighting environment from camera frame
  /// Returns: {lightType, kelvin, confidence}
  static Future<Map<String, dynamic>?> detectFromCamera() async {
    // This would require:
    // 1. Camera permission
    // 2. Capture frame
    // 3. Extract average RGB from neutral/white areas
    // 4. Convert RGB → XYZ → xy → CCT
    // 5. Map CCT to light type
    
    // Pseudo-implementation:
    /*
    final camera = await availableCameras();
    final controller = CameraController(...);
    await controller.initialize();
    
    final image = await controller.takePicture();
    final rgb = extractAverageRGB(image); // From neutral areas
    
    // Linearize RGB (gamma correction)
    final rLinear = gammaCorrection(rgb.r);
    final gLinear = gammaCorrection(rgb.g);
    final bLinear = gammaCorrection(rgb.b);
    
    // Convert to XYZ
    final xyz = rgbToXYZ(rLinear, gLinear, bLinear);
    
    // Calculate xy
    final xy = xyzToChromaticity(xyz);
    
    // Calculate CCT
    final kelvin = chromaticityToCCT_Hernandez(xy);
    
    // Map to light type
    final lightType = cctToLightType(kelvin);
    
    // Calculate confidence (based on D_uv)
    final duv = xy.distanceFromPlanckianLocus();
    final confidence = duv < 0.02 ? 0.9 : (duv < 0.05 ? 0.7 : 0.5);
    
    return {
      'lightType': lightType,
      'kelvin': kelvin,
      'confidence': confidence,
      'xy': xy,
    };
    */
    
    return null; // Placeholder
  }
  
  /// Gamma correction for sRGB
  static double gammaCorrection(double value) {
    if (value <= 0.04045) {
      return value / 12.92;
    } else {
      return pow((value + 0.055) / 1.055, 2.4).toDouble();
    }
  }
}
```

### Example 2: Heuristic-Based Detection (Fallback)

### New Service: `lib/services/lighting_detector.dart`

```dart
import '../utils/constants.dart';
import '../models/light_sample.dart';

class LightingDetector {
  /// Auto-detect lighting environment from sensor data
  static String detectLightingEnvironment({
    required DateTime time,
    required double currentLux,
    required List<LightSample> recentSamples, // Last 5-10 minutes
    double? screenBrightness,
  }) {
    final hour = time.hour;
    
    // Screen-dominant detection
    if (screenBrightness != null && screenBrightness > 0.5) {
      // Estimate if screen contributes >70% of light
      final estimatedScreenLux = _estimateScreenLux(screenBrightness);
      if (estimatedScreenLux > currentLux * 0.7) {
        return 'phone_screen';
      }
    }
    
    // Time-based + lux-based heuristics
    // Evening/Night (7 PM - 6 AM): Warm lighting likely
    if (hour >= 19 || hour < 6) {
      if (currentLux < 50) return 'warm_led_2700k';
      if (currentLux < 200) return 'neutral_led_4000k';
      return 'cool_led_5000k'; // Bright evening lighting
    }
    
    // Morning (6-10 AM): Daylight or cool LED likely
    if (hour >= 6 && hour < 10) {
      if (currentLux > 1000) return 'daylight_6500k';
      if (currentLux > 500) return 'cool_led_5000k';
      return 'neutral_led_4000k';
    }
    
    // Daytime (10 AM - 7 PM): Variable
    if (currentLux > 1000) {
      // Very bright = likely daylight
      return 'daylight_6500k';
    } else if (currentLux > 500) {
      // Bright = likely cool LED
      return 'cool_led_5000k';
    } else if (currentLux > 200) {
      // Moderate = likely neutral LED
      return 'neutral_led_4000k';
    } else {
      // Dim = likely warm LED
      return 'warm_led_2700k';
    }
  }
  
  static double _estimateScreenLux(double brightness) {
    return CircadianMath.interpolateFromMap(
      CircadianConstants.screenBrightnessToLux,
      brightness,
    );
  }
  
  /// Get confidence level for detection (0.0 to 1.0)
  static double getDetectionConfidence({
    required DateTime time,
    required double currentLux,
    required List<LightSample> recentSamples,
  }) {
    // Higher confidence for:
    // - Extreme lux values (< 20 or > 1000)
    // - Consistent lux patterns
    // - Time-of-day matches typical patterns
    
    if (currentLux < 20 || currentLux > 1000) {
      return 0.8; // High confidence for extreme values
    }
    
    // Check consistency
    if (recentSamples.length > 5) {
      final luxValues = recentSamples.map((s) => s.ambientLux).toList();
      final variance = _calculateVariance(luxValues);
      if (variance < 100) {
        return 0.7; // Medium-high confidence for stable lighting
      }
    }
    
    return 0.5; // Medium confidence for ambiguous cases
  }
  
  static double _calculateVariance(List<double> values) {
    if (values.isEmpty) return 0.0;
    final mean = values.reduce((a, b) => a + b) / values.length;
    final squaredDiffs = values.map((v) => (v - mean) * (v - mean)).toList();
    return squaredDiffs.reduce((a, b) => a + b) / values.length;
  }
}
```

### Integration in Recording Screen

```dart
// In recording_screen.dart
String _detectedLightType = 'neutral_led_4000k';
double _detectionConfidence = 0.0;

void _updateLightingDetection() {
  if (_sensorService.sampleStream == null) return;
  
  // Get recent samples (last 5 minutes)
  final recentSamples = _recentSamples.takeLast(30).toList(); // ~30 samples = 5 min
  
  final detected = LightingDetector.detectLightingEnvironment(
    time: DateTime.now(),
    currentLux: _currentLux,
    recentSamples: recentSamples,
    screenBrightness: _screenBrightness,
  );
  
  final confidence = LightingDetector.getDetectionConfidence(
    time: DateTime.now(),
    currentLux: _currentLux,
    recentSamples: recentSamples,
  );
  
  setState(() {
    _detectedLightType = detected;
    _detectionConfidence = confidence;
    // Auto-select if confidence is high
    if (confidence > 0.7 && _selectedLightType != detected) {
      _selectedLightType = detected;
    }
  });
}

// Show in UI
Widget _buildLightingSelector() {
  return Column(
    children: [
      if (_detectionConfidence > 0.5)
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.auto_awesome, size: 16),
              SizedBox(width: 8),
              Text(
                'Detected: ${_getLightTypeName(_detectedLightType)} '
                '(${(_detectionConfidence * 100).toStringAsFixed(0)}% confidence)',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      DropdownButtonFormField<String>(
        value: _selectedLightType,
        // ... existing dropdown code
      ),
    ],
  );
}
```

---

## Summary

### ✅ **Yes, automatic detection is possible!**

**Recommended Approach:**
1. **Start with heuristic-based detection** (time + lux patterns)
2. **Show detected value with confidence level**
3. **Allow user to override** if detection is wrong
4. **Learn from corrections** to improve accuracy

**Benefits:**
- ✅ No additional permissions needed
- ✅ Works on all devices
- ✅ Low battery impact
- ✅ Can be implemented quickly
- ✅ Improves user experience (less manual selection)

**Limitations:**
- ⚠️ Not 100% accurate (but good enough for most cases)
- ⚠️ May need user correction occasionally
- ⚠️ Works best with typical lighting patterns

Would you like me to implement the heuristic-based auto-detection feature?
