// lib/services/lighting_environment_detector.dart
//
// Step 7: Main Detector Service for Lighting Environment Detection
// Developer B Implementation - Now using Developer A's color conversion (Step 9 integration complete)
//
// This service:
// - Integrates camera service (Step 5)
// - Integrates image processor (Step 6)
// - Uses Developer A's real CIE 1931 xy color conversion
// - Provides heuristic fallback
// - Calculates confidence scores
// - Auto-detects using best available method

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'camera_color_detector.dart';
import 'image_processor.dart';
import '../core/cie_color_space.dart';
import '../core/cie_color_converter.dart';
import '../core/cct_calculator.dart';
import '../core/light_type_mapper.dart';
import '../models/light_sample.dart';
import '../utils/constants.dart';

/// Result of lighting environment detection
class LightingDetectionResult {
  final String lightType;
  final double? kelvin; // May be null for heuristic method
  final double confidence;
  final String method; // 'cie_xy' or 'heuristic'
  final CIE_Chromaticity? chromaticity; // Only for CIE xy method
  final double? duv; // Only for CIE xy method
  
  const LightingDetectionResult({
    required this.lightType,
    this.kelvin,
    required this.confidence,
    required this.method,
    this.chromaticity,
    this.duv,
  });
  
  /// Convert to map for easy serialization/UI display
  Map<String, dynamic> toMap() {
    return {
      'lightType': lightType,
      'kelvin': kelvin,
      'confidence': confidence,
      'method': method,
      'chromaticity': chromaticity != null 
          ? {'x': chromaticity!.x, 'y': chromaticity!.y}
          : null,
      'duv': duv,
    };
  }
  
  @override
  String toString() {
    final kelvinStr = kelvin != null ? '${kelvin!.toStringAsFixed(0)}K' : 'N/A';
    return 'LightingDetectionResult($lightType, $kelvinStr, '
        'confidence: ${(confidence * 100).toStringAsFixed(1)}%, method: $method)';
  }
}

/// Unified service for detecting lighting environment
/// 
/// Combines:
/// - CIE xy detection (camera-based, when available)
/// - Heuristic fallback (time + lux-based)
/// 
/// Uses mock color conversion until Developer A's code is integrated.
class LightingEnvironmentDetector {
  final CameraColorDetector _cameraDetector = CameraColorDetector();
  bool _cameraAvailable = false;
  bool _isInitialized = false;
  
  /// Check if camera is available and initialized
  bool get isCameraAvailable => _cameraAvailable && _isInitialized;
  
  /// Get camera preview widget (for UI integration in Step 8)
  Widget? getCameraPreview() {
    if (!isCameraAvailable) return null;
    return _cameraDetector.getPreviewWidget();
  }
  
  /// Initialize detector (check camera availability)
  /// 
  /// Should be called before using the detector.
  Future<bool> initialize() async {
    if (_isInitialized) return _cameraAvailable;
    
    try {
      _cameraAvailable = await _cameraDetector.initialize();
      _isInitialized = true;
      
      if (kDebugMode) {
        debugPrint('LightingEnvironmentDetector: Initialized');
        debugPrint('LightingEnvironmentDetector: Camera available: $_cameraAvailable');
      }
      
      return _cameraAvailable;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('LightingEnvironmentDetector: Error initializing: $e');
        debugPrint('LightingEnvironmentDetector: Stack trace: $stackTrace');
      }
      _cameraAvailable = false;
      _isInitialized = true; // Mark as initialized even on error
      return false;
    }
  }
  
  /// Dispose resources
  /// 
  /// Should be called when done with the detector.
  Future<void> dispose() async {
    await _cameraDetector.dispose();
    _cameraAvailable = false;
    _isInitialized = false;
    
    if (kDebugMode) {
      debugPrint('LightingEnvironmentDetector: Disposed');
    }
  }
  
  /// Detect lighting environment using CIE xy (camera-based)
  /// 
  /// Pipeline:
  /// 1. Capture image from camera
  /// 2. Extract RGB from image
  /// 3. Convert RGB → xy (mock)
  /// 4. Convert xy → CCT (mock)
  /// 5. Map CCT → light type
  /// 6. Calculate confidence
  /// 
  /// Returns null if detection fails or camera unavailable.
  Future<LightingDetectionResult?> detectWithCamera() async {
    if (!isCameraAvailable) {
      if (kDebugMode) {
        debugPrint('LightingEnvironmentDetector: Camera not available');
      }
      return null;
    }
    
    try {
      if (kDebugMode) {
        debugPrint('LightingEnvironmentDetector: Starting camera-based detection...');
      }
      
      // Step 1: Capture image
      final cameraResult = await _cameraDetector.captureImage();
      if (cameraResult == null) {
        if (kDebugMode) {
          debugPrint('LightingEnvironmentDetector: Failed to capture image');
        }
        return null;
      }
      
      // Step 2: Extract RGB from image
      final rgbResult = ImageProcessor.extractRGBFromCameraImage(cameraResult);
      if (!rgbResult.isValid) {
        if (kDebugMode) {
          debugPrint('LightingEnvironmentDetector: Failed to extract RGB: ${rgbResult.error}');
        }
        return null;
      }
      
      if (kDebugMode) {
        debugPrint('LightingEnvironmentDetector: Extracted RGB: ${rgbResult.rgb}');
      }
      
      // Step 3: Convert RGB → xy (Developer A's real CIE 1931 implementation)
      final chromaticity = ColorConverter.rgbToChromaticity(rgbResult.rgb);
      
      // Step 4: Convert xy → CCT (Developer A's Hernández-Andrés method)
      final kelvin = CCT_Calc.chromaticityToCCT(chromaticity);
      
      // Step 5: Calculate D_uv (Developer A's implementation)
      final duv = CCT_Calc.calculateDUV(chromaticity);
      
      // Step 6: Map CCT → light type (Developer A's LightTypeMapper)
      final lightType = LightTypeMapper.cctToLightType(kelvin);
      
      // Step 7: Calculate confidence (Developer A's LightTypeMapper)
      final confidence = LightTypeMapper.calculateConfidence(
        duv: duv,
        kelvin: kelvin,
      );
      
      if (kDebugMode) {
        debugPrint('LightingEnvironmentDetector: Detection complete');
        debugPrint('LightingEnvironmentDetector: Result - $lightType, '
            '${kelvin.toStringAsFixed(0)}K, confidence: ${(confidence * 100).toStringAsFixed(1)}%');
      }
      
      return LightingDetectionResult(
        lightType: lightType,
        kelvin: kelvin,
        confidence: confidence,
        method: 'cie_xy',
        chromaticity: chromaticity,
        duv: duv,
      );
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('LightingEnvironmentDetector: Error in camera detection: $e');
        debugPrint('LightingEnvironmentDetector: Stack trace: $stackTrace');
      }
      return null;
    }
  }
  
  /// Detect lighting environment using heuristics (fallback)
  /// 
  /// Uses:
  /// - Time of day
  /// - Current lux level
  /// - Screen brightness (if available)
  /// - Recent sample patterns
  /// 
  /// Returns heuristic-based detection result.
  LightingDetectionResult detectWithHeuristics({
    required DateTime time,
    required double currentLux,
    required List<LightSample> recentSamples,
    double? screenBrightness,
  }) {
    if (kDebugMode) {
      debugPrint('LightingEnvironmentDetector: Starting heuristic detection...');
    }
    
    // Screen-dominant detection
    if (screenBrightness != null && screenBrightness > 0.5) {
      // Estimate if screen contributes >70% of light
      final estimatedScreenLux = _estimateScreenLux(screenBrightness);
      if (estimatedScreenLux > currentLux * 0.7) {
        if (kDebugMode) {
          debugPrint('LightingEnvironmentDetector: Detected screen-dominant lighting');
        }
        return const LightingDetectionResult(
          lightType: 'phone_screen',
          confidence: 0.7,
          method: 'heuristic',
        );
      }
    }
    
    // Time-based + lux-based heuristics
    final hour = time.hour;
    String lightType;
    double confidence = 0.6; // Medium confidence for heuristics
    
    // Evening/Night (7 PM - 6 AM): Warm lighting likely
    if (hour >= 19 || hour < 6) {
      if (currentLux < 50) {
        lightType = 'warm_led_2700k';
        confidence = 0.7;
      } else if (currentLux < 200) {
        lightType = 'neutral_led_4000k';
        confidence = 0.6;
      } else {
        lightType = 'cool_led_5000k';
        confidence = 0.5;
      }
    }
    // Morning (6-10 AM): Daylight or cool LED likely
    else if (hour >= 6 && hour < 10) {
      if (currentLux > 1000) {
        lightType = 'daylight_6500k';
        confidence = 0.8;
      } else if (currentLux > 500) {
        lightType = 'cool_led_5000k';
        confidence = 0.7;
      } else {
        lightType = 'neutral_led_4000k';
        confidence = 0.6;
      }
    }
    // Daytime (10 AM - 7 PM): Variable
    else {
      if (currentLux > 1000) {
        lightType = 'daylight_6500k';
        confidence = 0.8;
      } else if (currentLux > 500) {
        lightType = 'cool_led_5000k';
        confidence = 0.7;
      } else if (currentLux > 200) {
        lightType = 'neutral_led_4000k';
        confidence = 0.6;
      } else {
        lightType = 'warm_led_2700k';
        confidence = 0.6;
      }
    }
    
    if (kDebugMode) {
      debugPrint('LightingEnvironmentDetector: Heuristic detection complete');
      debugPrint('LightingEnvironmentDetector: Result - $lightType, '
          'confidence: ${(confidence * 100).toStringAsFixed(1)}%');
    }
    
    return LightingDetectionResult(
      lightType: lightType,
      confidence: confidence,
      method: 'heuristic',
    );
  }
  
  /// Auto-detect using best available method
  /// 
  /// Strategy:
  /// 1. Try camera-based detection if available and preferred
  /// 2. Fall back to heuristics if camera fails or unavailable
  /// 
  /// Parameters:
  /// - `preferCamera`: If true, tries camera first (default: true)
  /// - Other parameters used for heuristic fallback
  /// 
  /// Returns detection result from best available method.
  Future<LightingDetectionResult> autoDetect({
    required DateTime time,
    required double currentLux,
    required List<LightSample> recentSamples,
    double? screenBrightness,
    bool preferCamera = true,
  }) async {
    // Try camera first if available and preferred
    if (preferCamera && isCameraAvailable) {
      final cameraResult = await detectWithCamera();
      if (cameraResult != null && cameraResult.confidence > 0.5) {
        if (kDebugMode) {
          debugPrint('LightingEnvironmentDetector: Using camera-based detection');
        }
        return cameraResult;
      }
      
      if (kDebugMode) {
        debugPrint('LightingEnvironmentDetector: Camera detection failed or low confidence, '
            'falling back to heuristics');
      }
    }
    
    // Fall back to heuristics
    if (kDebugMode) {
      debugPrint('LightingEnvironmentDetector: Using heuristic detection');
    }
    return detectWithHeuristics(
      time: time,
      currentLux: currentLux,
      recentSamples: recentSamples,
      screenBrightness: screenBrightness,
    );
  }
  
  /// Estimate screen lux from brightness value
  double _estimateScreenLux(double brightness) {
    return CircadianMath.interpolateFromMap(
      CircadianConstants.screenBrightnessToLux,
      brightness,
    );
  }
}
