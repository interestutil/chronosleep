// test/integration/processing_pipeline_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:chronotherapy_app/services/processing_pipeline.dart';
import 'package:chronotherapy_app/models/session_data.dart';
import 'package:chronotherapy_app/models/light_sample.dart';

void main() {
  group('ProcessingPipeline Integration', () {
    test('processes simple session correctly', () async {
      final pipeline = ProcessingPipeline();
      
      // Create a simple test session
      final now = DateTime.now().toUtc();
      final samples = List.generate(
        10,
        (i) => LightSample(
          timestamp: now.add(Duration(minutes: i)),
          ambientLux: 100.0,
          screenOn: false,
          screenBrightness: null,
        ),
      );
      
      final session = SessionData(
        id: 'test-session',
        startedAt: now,
        stoppedAt: now.add(const Duration(minutes: 10)),
        samples: samples,
      );
      
      final results = await pipeline.process(
        session: session,
        lightType: 'neutral_led_4000k',
      );
      
      // Verify results structure
      expect(results.sessionId, equals('test-session'));
      expect(results.timestamps.length, equals(10));
      expect(results.luxValues.length, equals(10));
      expect(results.melanopicValues.length, equals(10));
      expect(results.csValues.length, equals(10));
      
      // Verify calculations are reasonable
      expect(results.totalDoseX, greaterThan(0.0));
      expect(results.msiPredicted, greaterThanOrEqualTo(0.0));
      expect(results.msiPredicted, lessThanOrEqualTo(1.0));
      expect(results.averageCS, greaterThanOrEqualTo(0.0));
      expect(results.averageCS, lessThanOrEqualTo(0.7));
    });

    test('handles empty session', () async {
      final pipeline = ProcessingPipeline();
      
      final session = SessionData(
        id: 'empty-session',
        startedAt: DateTime.now(),
        stoppedAt: DateTime.now(),
        samples: [],
      );
      
      expect(
        () => pipeline.process(session: session),
        throwsArgumentError,
      );
    });

    test('calculates dose correctly for known input', () async {
      final pipeline = ProcessingPipeline();
      
      final now = DateTime.now().toUtc();
      // Create samples with known CS values
      // Using 100 lux with neutral_led_4000k (ratio 0.6) = 60 melanopic lux
      // CS ≈ 0.7 * (1 - exp(-0.005 * 60)) ≈ 0.18
      final samples = List.generate(
        60, // 60 samples = 1 hour if 1 minute intervals
        (i) => LightSample(
          timestamp: now.add(Duration(minutes: i)),
          ambientLux: 100.0,
          screenOn: false,
          screenBrightness: null,
        ),
      );
      
      final session = SessionData(
        id: 'known-input',
        startedAt: now,
        stoppedAt: now.add(const Duration(hours: 1)),
        samples: samples,
      );
      
      final results = await pipeline.process(
        session: session,
        lightType: 'neutral_led_4000k',
      );
      
      // Verify dose is approximately CS * duration
      // Expected: ~0.18 CS * 1 hour ≈ 0.18 CS·h
      expect(results.totalDoseX, greaterThan(0.1));
      expect(results.totalDoseX, lessThan(0.3));
      
      // MSI should be calculated from dose
      expect(results.msiPredicted, greaterThan(0.0));
      expect(results.msiPredicted, lessThan(0.1)); // Low dose = low MSI
    });
  });
}

