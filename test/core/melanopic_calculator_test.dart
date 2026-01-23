// test/core/melanopic_calculator_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:chronotherapy_app/core/melanopic_calculator.dart';
import 'package:chronotherapy_app/models/light_sample.dart';

void main() {
  group('MelanopicCalculator', () {
    test('calculateMelanopicEDI applies correct ratio', () {
      // Neutral LED 4000K has ratio 0.60
      final melanopic = MelanopicCalculator.calculateMelanopicEDI(
        totalLux: 100.0,
        lightType: 'neutral_led_4000k',
      );
      expect(melanopic, equals(60.0));
      
      // Warm LED 2700K has ratio 0.45
      final melanopicWarm = MelanopicCalculator.calculateMelanopicEDI(
        totalLux: 100.0,
        lightType: 'warm_led_2700k',
      );
      expect(melanopicWarm, equals(45.0));
    });

    test('calculateMelanopicEDI uses default ratio for unknown type', () {
      final melanopic = MelanopicCalculator.calculateMelanopicEDI(
        totalLux: 100.0,
        lightType: 'unknown_type',
      );
      // Should use default ratio (0.6 from code)
      expect(melanopic, equals(60.0));
    });

    test('calculateTotalLuxAtEye includes screen contribution', () {
      final sample = LightSample(
        timestamp: DateTime.now(),
        ambientLux: 50.0,
        screenOn: true,
        screenBrightness: 0.5,
      );
      
      final totalLux = MelanopicCalculator.calculateTotalLuxAtEye(sample);
      // Should be ambient + screen contribution
      // Screen brightness 0.5 maps to ~120 lux (from constants)
      expect(totalLux, greaterThan(50.0));
      expect(totalLux, closeTo(170.0, 20.0)); // Allow some variance
    });

    test('calculateTotalLuxAtEye excludes screen when off', () {
      final sample = LightSample(
        timestamp: DateTime.now(),
        ambientLux: 50.0,
        screenOn: false,
        screenBrightness: null,
      );
      
      final totalLux = MelanopicCalculator.calculateTotalLuxAtEye(sample);
      expect(totalLux, equals(50.0));
    });

    test('processSample combines all calculations', () {
      final sample = LightSample(
        timestamp: DateTime.now(),
        ambientLux: 100.0,
        screenOn: false,
        screenBrightness: null,
      );
      
      final melanopic = MelanopicCalculator.processSample(
        sample: sample,
        lightType: 'neutral_led_4000k',
      );
      
      // 100 lux * 0.60 ratio = 60 melanopic lux
      expect(melanopic, equals(60.0));
    });
  });
}

