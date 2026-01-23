// test/services/image_processor_test.dart
//
// Unit tests for ImageProcessor (Step 6)
// Developer B - Independent testing

import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:chronotherapy_app/services/image_processor.dart';
import 'package:chronotherapy_app/core/cie_color_space.dart';
import 'package:image/image.dart' as img;

void main() {
  group('ImageProcessor', () {
    test('RGB class basic functionality', () {
      final rgb1 = RGB(r: 0.5, g: 0.6, b: 0.7);
      final rgb2 = RGB(r: 0.5, g: 0.6, b: 0.7);
      final rgb3 = RGB(r: 0.5, g: 0.6, b: 0.8);
      
      // Developer A's RGB class - check values directly
      expect(rgb1.r, equals(rgb2.r));
      expect(rgb1.g, equals(rgb2.g));
      expect(rgb1.b, equals(rgb2.b));
      expect(rgb1.b, isNot(equals(rgb3.b))); // Different b values
      expect(rgb1.isValid, isTrue);
    });
    
    test('extractAverageRGB handles invalid image bytes', () {
      final invalidBytes = Uint8List.fromList([0, 1, 2, 3]);
      final result = ImageProcessor.extractAverageRGB(invalidBytes);
      
      expect(result.isValid, isFalse);
      expect(result.error, isNotNull);
      expect(result.sampleCount, equals(0));
    });
    
    test('extractAverageRGB processes valid image', () {
      // Create a simple test image (white image)
      final image = img.Image(width: 100, height: 100);
      img.fill(image, color: img.ColorRgb8(255, 255, 255));
      
      final imageBytes = Uint8List.fromList(img.encodeJpg(image));
      final result = ImageProcessor.extractAverageRGB(imageBytes);
      
      expect(result.isValid, isTrue);
      expect(result.error, isNull);
      expect(result.sampleCount, greaterThan(0));
      
      // White image should have high RGB values
      expect(result.rgb.r, greaterThan(0.9));
      expect(result.rgb.g, greaterThan(0.9));
      expect(result.rgb.b, greaterThan(0.9));
    });
    
    test('extractAverageRGB processes colored image', () {
      // Create a red image
      final image = img.Image(width: 100, height: 100);
      img.fill(image, color: img.ColorRgb8(255, 0, 0));
      
      final imageBytes = Uint8List.fromList(img.encodeJpg(image));
      final result = ImageProcessor.extractAverageRGB(imageBytes);
      
      expect(result.isValid, isTrue);
      expect(result.rgb.r, greaterThan(result.rgb.g));
      expect(result.rgb.r, greaterThan(result.rgb.b));
    });
    
    test('extractRGBFromRegion extracts from specific region', () {
      // Create a test image with different colors in different regions
      final image = img.Image(width: 200, height: 200);
      
      // Fill left half with red
      for (int y = 0; y < 200; y++) {
        for (int x = 0; x < 100; x++) {
          image.setPixel(x, y, img.ColorRgb8(255, 0, 0));
        }
      }
      
      // Fill right half with blue
      for (int y = 0; y < 200; y++) {
        for (int x = 100; x < 200; x++) {
          image.setPixel(x, y, img.ColorRgb8(0, 0, 255));
        }
      }
      
      final imageBytes = Uint8List.fromList(img.encodeJpg(image));
      
      // Extract from left region (should be red)
      final leftResult = ImageProcessor.extractRGBFromRegion(
        imageBytes,
        x: 0,
        y: 0,
        width: 100,
        height: 200,
      );
      
      expect(leftResult.isValid, isTrue);
      expect(leftResult.rgb.r, greaterThan(leftResult.rgb.b));
      
      // Extract from right region (should be blue)
      final rightResult = ImageProcessor.extractRGBFromRegion(
        imageBytes,
        x: 100,
        y: 0,
        width: 100,
        height: 200,
      );
      
      expect(rightResult.isValid, isTrue);
      expect(rightResult.rgb.b, greaterThan(rightResult.rgb.r));
    });
    
    test('extractRGBFromRegion handles invalid region', () {
      final image = img.Image(width: 100, height: 100);
      img.fill(image, color: img.ColorRgb8(128, 128, 128));
      final imageBytes = Uint8List.fromList(img.encodeJpg(image));
      
      // Try to extract from region outside image bounds
      final result = ImageProcessor.extractRGBFromRegion(
        imageBytes,
        x: 200,
        y: 200,
        width: 100,
        height: 100,
      );
      
      expect(result.isValid, isFalse);
      expect(result.error, isNotNull);
    });
    
    test('extractAverageRGB with custom parameters', () {
      final image = img.Image(width: 200, height: 200);
      img.fill(image, color: img.ColorRgb8(200, 200, 200));
      final imageBytes = Uint8List.fromList(img.encodeJpg(image));
      
      // Test with more sample regions
      final result1 = ImageProcessor.extractAverageRGB(
        imageBytes,
        sampleRegions: 16, // 4x4 grid
      );
      
      expect(result1.isValid, isTrue);
      expect(result1.sampleCount, equals(16));
      
      // Test with different neutral threshold
      final result2 = ImageProcessor.extractAverageRGB(
        imageBytes,
        neutralThreshold: 0.05, // Stricter threshold
      );
      
      expect(result2.isValid, isTrue);
    });
    
    test('RGBExtractionResult provides metadata', () {
      final image = img.Image(width: 100, height: 100);
      img.fill(image, color: img.ColorRgb8(255, 255, 255));
      final imageBytes = Uint8List.fromList(img.encodeJpg(image));
      
      final result = ImageProcessor.extractAverageRGB(imageBytes);
      
      expect(result.isValid, isTrue);
      expect(result.sampleCount, greaterThan(0));
      expect(result.neutralRegionRatio, greaterThanOrEqualTo(0.0));
      expect(result.neutralRegionRatio, lessThanOrEqualTo(1.0));
    });
  });
}
