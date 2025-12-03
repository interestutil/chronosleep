// test/core/cs_model_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:chronotherapy_app/core/cs_model.dart';
import 'package:chronotherapy_app/utils/constants.dart';

void main() {
  group('CSModel', () {
    test('calculateCS returns 0 for zero or negative melanopic EDI', () {
      const model = CSModel();
      expect(model.calculateCS(0.0), equals(0.0));
      expect(model.calculateCS(-10.0), equals(0.0));
    });

    test('calculateCS follows exponential model', () {
      const model = CSModel();
      
      // Test with known values
      // For melanopic EDI = 200, CS should be approximately:
      // CS = 0.7 * (1 - exp(-0.005 * 200)) = 0.7 * (1 - exp(-1)) ≈ 0.7 * 0.632 ≈ 0.442
      final cs200 = model.calculateCS(200.0);
      expect(cs200, greaterThan(0.4));
      expect(cs200, lessThan(0.5));
      
      // For melanopic EDI = 1000, should approach CS_max
      final cs1000 = model.calculateCS(1000.0);
      expect(cs1000, greaterThan(0.6));
      expect(cs1000, lessThanOrEqualTo(CircadianConstants.csMax));
    });

    test('calculateCS clamps to csMax', () {
      const model = CSModel();
      final csVeryHigh = model.calculateCS(10000.0);
      expect(csVeryHigh, lessThanOrEqualTo(CircadianConstants.csMax));
    });

    test('calculateCSLinear provides linear approximation', () {
      // Linear: CS = melanopic_EDI / 1000, capped at csMax
      expect(CSModel.calculateCSLinear(500.0), equals(0.5));
      expect(CSModel.calculateCSLinear(1000.0), lessThanOrEqualTo(CircadianConstants.csMax));
      expect(CSModel.calculateCSLinear(2000.0), lessThanOrEqualTo(CircadianConstants.csMax));
    });

    test('fitParameterA recovers parameter from observation', () {
      const melanopicEDI = 200.0;
      const csObserved = 0.442;
      
      final fittedA = CSModel.fitParameterA(
        melanopicEDI: melanopicEDI,
        csObserved: csObserved,
      );
      
      // Should be close to default a (0.005)
      expect(fittedA, greaterThan(0.004));
      expect(fittedA, lessThan(0.006));
    });
  });
}

