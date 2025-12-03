// test/core/prc_model_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:chronotherapy_app/core/prc_model.dart';

void main() {
  group('PRCModel', () {
    test('getPRCWeight returns correct weights for known hours', () {
      // Morning should have positive (advance) weights
      final morning8 = PRCModel.getPRCWeight(DateTime(2024, 1, 1, 8, 0));
      expect(morning8, greaterThan(0.0));
      
      // Evening should have negative (delay) weights
      final evening20 = PRCModel.getPRCWeight(DateTime(2024, 1, 1, 20, 0));
      expect(evening20, lessThan(0.0));
      
      // Noon should have minimal effect
      final noon = PRCModel.getPRCWeight(DateTime(2024, 1, 1, 12, 0));
      expect(noon, closeTo(0.0, 0.1));
    });

    test('calculatePhaseShift returns 0 for zero dose', () {
      final shift = PRCModel.calculatePhaseShift(
        time: DateTime(2024, 1, 1, 8, 0),
        doseX: 0.0,
      );
      expect(shift, equals(0.0));
    });

    test('calculatePhaseShift applies morning advance correctly', () {
      // Morning exposure should advance phase (positive shift)
      final shift = PRCModel.calculatePhaseShift(
        time: DateTime(2024, 1, 1, 8, 0), // 8 AM
        doseX: 1.0, // 1 CS·hour
      );
      expect(shift, greaterThan(0.0));
    });

    test('calculatePhaseShift applies evening delay correctly', () {
      // Evening exposure should delay phase (negative shift)
      final shift = PRCModel.calculatePhaseShift(
        time: DateTime(2024, 1, 1, 22, 0), // 10 PM
        doseX: 1.0, // 1 CS·hour
      );
      expect(shift, lessThan(0.0));
    });

    test('calculateCumulativePhaseShift sums multiple exposures', () {
      final times = [
        DateTime(2024, 1, 1, 8, 0),  // Morning (advance)
        DateTime(2024, 1, 1, 22, 0), // Evening (delay)
      ];
      final doses = [0.5, 0.5]; // 0.5 CS·hour each
      
      final totalShift = PRCModel.calculateCumulativePhaseShift(
        times: times,
        doses: doses,
      );
      
      // Should be sum of morning advance and evening delay
      // Result depends on PRC weights, but should be non-zero
      expect(totalShift, isNot(equals(0.0)));
    });

    test('calculateCumulativePhaseShift throws on mismatched lengths', () {
      expect(() {
        PRCModel.calculateCumulativePhaseShift(
          times: [DateTime(2024, 1, 1, 8, 0)],
          doses: [0.5, 0.5],
        );
      }, throwsArgumentError);
    });

    test('interpretPhaseShift provides correct interpretation', () {
      // Minimal shift
      final minimal = PRCModel.interpretPhaseShift(0.05);
      expect(minimal, contains('Minimal'));
      
      // Advance
      final advance = PRCModel.interpretPhaseShift(0.5);
      expect(advance, contains('advance'));
      expect(advance, contains('earlier'));
      
      // Delay
      final delay = PRCModel.interpretPhaseShift(-0.5);
      expect(delay, contains('delay'));
      expect(delay, contains('later'));
    });
  });
}

