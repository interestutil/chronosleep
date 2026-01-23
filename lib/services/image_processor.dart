// lib/services/image_processor.dart
//
// Step 6: Image Processor for RGB Extraction
// Developer B Implementation - Now using Developer A's RGB class

import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'camera_color_detector.dart';
import '../core/cie_color_space.dart';

/// Result of RGB extraction from image
class RGBExtractionResult {
  final RGB rgb;
  final int sampleCount;
  final double neutralRegionRatio; // Ratio of neutral regions found
  final String? error;
  
  const RGBExtractionResult({
    required this.rgb,
    required this.sampleCount,
    required this.neutralRegionRatio,
    this.error,
  });
  
  bool get isValid => error == null;
}

/// Processes camera images to extract RGB values for color temperature detection
/// 
/// This service:
/// - Decodes camera images
/// - Samples multiple regions (avoiding edges)
/// - Filters for neutral/white areas (better for color temperature estimation)
/// - Calculates weighted average RGB
/// - Returns RGB values normalized to 0.0-1.0 range
class ImageProcessor {
  /// Extract average RGB from image, focusing on neutral/white areas
  /// 
  /// Strategy:
  /// 1. Sample multiple regions (avoid edges, focus on center)
  /// 2. Filter for neutral colors (similar R, G, B values)
  /// 3. Calculate weighted average
  /// 
  /// Parameters:
  /// - `imageBytes`: Raw image bytes (JPEG format from camera)
  /// - `sampleRegions`: Number of regions to sample (default: 9, arranged in 3x3 grid)
  /// - `neutralThreshold`: Max difference between R, G, B for "neutral" classification (default: 0.15)
  /// 
  /// Returns: RGBExtractionResult with RGB values and metadata
  static RGBExtractionResult extractAverageRGB(
    Uint8List imageBytes, {
    int sampleRegions = 9,
    double neutralThreshold = 0.15,
  }) {
    try {
      // Decode image
      final image = img.decodeImage(imageBytes);
      if (image == null) {
        return const RGBExtractionResult(
          rgb: RGB(r: 0.5, g: 0.5, b: 0.5), // Fallback
          sampleCount: 0,
          neutralRegionRatio: 0.0,
          error: 'Failed to decode image',
        );
      }
      
      final width = image.width;
      final height = image.height;
      
      if (width == 0 || height == 0) {
        return const RGBExtractionResult(
          rgb: RGB(r: 0.5, g: 0.5, b: 0.5),
          sampleCount: 0,
          neutralRegionRatio: 0.0,
          error: 'Invalid image dimensions',
        );
      }
      
      if (kDebugMode) {
        debugPrint('ImageProcessor: Processing image ${width}x$height');
      }
      
      // Sample regions (avoid edges - 10% margin)
      final marginX = (width * 0.1).round();
      final marginY = (height * 0.1).round();
      final sampleWidth = width - 2 * marginX;
      final sampleHeight = height - 2 * marginY;
      
      // Calculate grid dimensions
      final gridSize = math.sqrt(sampleRegions).round();
      final regionWidth = sampleWidth ~/ gridSize;
      final regionHeight = sampleHeight ~/ gridSize;
      
      final rgbSamples = <RGB>[];
      int neutralCount = 0;
      
      // Sample each region
      for (int i = 0; i < gridSize; i++) {
        for (int j = 0; j < gridSize; j++) {
          final startX = marginX + i * regionWidth;
          final startY = marginY + j * regionHeight;
          final endX = (startX + regionWidth).clamp(0, width);
          final endY = (startY + regionHeight).clamp(0, height);
          
          // Calculate average RGB for this region
          double rSum = 0.0, gSum = 0.0, bSum = 0.0;
          int pixelCount = 0;
          
          for (int y = startY; y < endY; y++) {
            for (int x = startX; x < endX; x++) {
              final pixel = image.getPixel(x, y);
              final r = (pixel.r / 255.0);
              final g = (pixel.g / 255.0);
              final b = (pixel.b / 255.0);
              
              rSum += r;
              gSum += g;
              bSum += b;
              pixelCount++;
            }
          }
          
          if (pixelCount > 0) {
            final avgR = rSum / pixelCount;
            final avgG = gSum / pixelCount;
            final avgB = bSum / pixelCount;
            
            final rgb = RGB(r: avgR, g: avgG, b: avgB);
            
            // Check if region is "neutral" (similar R, G, B values)
            final maxDiff = [
              (rgb.r - rgb.g).abs(),
              (rgb.r - rgb.b).abs(),
              (rgb.g - rgb.b).abs(),
            ].reduce((a, b) => a > b ? a : b);
            
            if (maxDiff < neutralThreshold) {
              neutralCount++;
            }
            
            rgbSamples.add(rgb);
          }
        }
      }
      
      if (rgbSamples.isEmpty) {
        // Fallback: use center pixel
        final centerX = width ~/ 2;
        final centerY = height ~/ 2;
        final pixel = image.getPixel(centerX, centerY);
        final fallbackRgb = RGB(
          r: pixel.r / 255.0,
          g: pixel.g / 255.0,
          b: pixel.b / 255.0,
        );
        
        if (kDebugMode) {
          debugPrint('ImageProcessor: No samples found, using center pixel fallback');
        }
        
        return RGBExtractionResult(
          rgb: fallbackRgb,
          sampleCount: 1,
          neutralRegionRatio: 0.0,
        );
      }
      
      // Calculate weighted average (weight neutral regions more heavily)
      double rSum = 0.0, gSum = 0.0, bSum = 0.0;
      double weightSum = 0.0;
      
      for (final rgb in rgbSamples) {
        final maxDiff = [
          (rgb.r - rgb.g).abs(),
          (rgb.r - rgb.b).abs(),
          (rgb.g - rgb.b).abs(),
        ].reduce((a, b) => a > b ? a : b);
        
        // Weight neutral regions 2x more than non-neutral
        final weight = maxDiff < neutralThreshold ? 2.0 : 1.0;
        
        rSum += rgb.r * weight;
        gSum += rgb.g * weight;
        bSum += rgb.b * weight;
        weightSum += weight;
      }
      
      final finalRgb = RGB(
        r: rSum / weightSum,
        g: gSum / weightSum,
        b: bSum / weightSum,
      );
      
      final neutralRatio = rgbSamples.isEmpty 
          ? 0.0 
          : neutralCount / rgbSamples.length;
      
      if (kDebugMode) {
        debugPrint('ImageProcessor: Extracted RGB: $finalRgb');
        debugPrint('ImageProcessor: Sample count: ${rgbSamples.length}, '
            'Neutral regions: $neutralCount (${(neutralRatio * 100).toStringAsFixed(1)}%)');
      }
      
      return RGBExtractionResult(
        rgb: finalRgb,
        sampleCount: rgbSamples.length,
        neutralRegionRatio: neutralRatio,
      );
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('ImageProcessor: Error extracting RGB: $e');
        debugPrint('ImageProcessor: Stack trace: $stackTrace');
      }
      
      return RGBExtractionResult(
        rgb: const RGB(r: 0.5, g: 0.5, b: 0.5),
        sampleCount: 0,
        neutralRegionRatio: 0.0,
        error: 'Exception: $e',
      );
    }
  }
  
  /// Extract RGB from specific image region (for testing/debugging)
  /// 
  /// Parameters:
  /// - `imageBytes`: Raw image bytes
  /// - `x`, `y`: Top-left corner of region
  /// - `width`, `height`: Size of region
  /// 
  /// Returns: RGBExtractionResult with average RGB of the region
  static RGBExtractionResult extractRGBFromRegion(
    Uint8List imageBytes, {
    required int x,
    required int y,
    required int width,
    required int height,
  }) {
    try {
      final image = img.decodeImage(imageBytes);
      if (image == null) {
        return const RGBExtractionResult(
          rgb: RGB(r: 0.5, g: 0.5, b: 0.5),
          sampleCount: 0,
          neutralRegionRatio: 0.0,
          error: 'Failed to decode image',
        );
      }
      
      double rSum = 0.0, gSum = 0.0, bSum = 0.0;
      int pixelCount = 0;
      
      final endX = (x + width).clamp(0, image.width);
      final endY = (y + height).clamp(0, image.height);
      
      for (int py = y; py < endY; py++) {
        for (int px = x; px < endX; px++) {
          final pixel = image.getPixel(px, py);
          rSum += pixel.r / 255.0;
          gSum += pixel.g / 255.0;
          bSum += pixel.b / 255.0;
          pixelCount++;
        }
      }
      
      if (pixelCount == 0) {
        return const RGBExtractionResult(
          rgb: RGB(r: 0.5, g: 0.5, b: 0.5),
          sampleCount: 0,
          neutralRegionRatio: 0.0,
          error: 'No pixels in region',
        );
      }
      
      final rgb = RGB(
        r: rSum / pixelCount,
        g: gSum / pixelCount,
        b: bSum / pixelCount,
      );
      
      return RGBExtractionResult(
        rgb: rgb,
        sampleCount: pixelCount,
        neutralRegionRatio: 0.0, // Not calculated for single region
      );
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('ImageProcessor: Error extracting RGB from region: $e');
        debugPrint('ImageProcessor: Stack trace: $stackTrace');
      }
      
      return RGBExtractionResult(
        rgb: const RGB(r: 0.5, g: 0.5, b: 0.5),
        sampleCount: 0,
        neutralRegionRatio: 0.0,
        error: 'Exception: $e',
      );
    }
  }
  
  /// Convenience method to extract RGB from CameraImageResult
  /// 
  /// This is the main entry point for Step 6 integration with Step 5.
  static RGBExtractionResult extractRGBFromCameraImage(
    CameraImageResult cameraResult, {
    int sampleRegions = 9,
    double neutralThreshold = 0.15,
  }) {
    return extractAverageRGB(
      cameraResult.imageBytes,
      sampleRegions: sampleRegions,
      neutralThreshold: neutralThreshold,
    );
  }
}
