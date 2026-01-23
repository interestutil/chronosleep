// test/core/msi_model_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:chronotherapy_app/core/msi_model.dart';

void main() {
  group('MSIModel', () {
    test('calculateMSI returns 0 for zero or negative dose', () {
      const model = MSIModel();
      expect(model.calculateMSI(0.0), equals(0.0));
      expect(model.calculateMSI(-10.0), equals(0.0));
    });

    test('calculateMSI follows exponential model', () {
      const model = MSIModel();
      
      // MSI = 1 - exp(-k * X)
      // For k=0.25 and X=1.0: MSI = 1 - exp(-0.25) ≈ 0.221
      final msi1 = model.calculateMSI(1.0);
      expect(msi1, closeTo(0.221, 0.01));
      
      // For X=4.0: MSI = 1 - exp(-1.0) ≈ 0.632
      final msi4 = model.calculateMSI(4.0);
      expect(msi4, closeTo(0.632, 0.01));
    });

    test('calculateMSI clamps to 1.0', () {
      const model = MSIModel();
      final msiVeryHigh = model.calculateMSI(100.0);
      expect(msiVeryHigh, lessThanOrEqualTo(1.0));
      expect(msiVeryHigh, greaterThan(0.99));
    });

    test('calculateDose sums CS values correctly', () {
      final csValues = [0.1, 0.2, 0.3, 0.4];
      const deltaT = 0.5; // 30 minutes
      
      final dose = MSIModel.calculateDose(
        csValues: csValues,
        deltaT: deltaT,
      );
      
      // Expected: (0.1 + 0.2 + 0.3 + 0.4) * 0.5 = 1.0 * 0.5 = 0.5
      expect(dose, equals(0.5));
    });

    test('fitK recovers parameter from observation', () {
      const doseX = 2.0;
      const msiObserved = 0.393; // 1 - exp(-0.25 * 2)
      
      final fittedK = MSIModel.fitK(
        msiObserved: msiObserved,
        doseX: doseX,
      );
      
      // Should be close to default k (0.25)
      expect(fittedK, closeTo(0.25, 0.01));
    });

    test('calculateMSIWithUncertainty provides confidence intervals', () {
      const model = MSIModel(k: 0.25);
      const doseX = 2.0;
      const kUncertainty = 0.05;
      
      final result = model.calculateMSIWithUncertainty(
        doseX: doseX,
        kUncertainty: kUncertainty,
      );
      
      expect(result['msi'], isNotNull);
      expect(result['lower_ci'], isNotNull);
      expect(result['upper_ci'], isNotNull);
      expect(result['lower_ci']!, lessThan(result['msi']!));
      expect(result['upper_ci']!, greaterThan(result['msi']!));
    });
  });
}

