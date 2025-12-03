# Results Verification Guide

This document explains how to verify that the calculation results are correct.

## Running Unit Tests

The project includes comprehensive unit tests for all core calculation models. Run them with:

```bash
flutter test
```

### Test Coverage

- **CS Model Tests** (`test/core/cs_model_test.dart`)
  - Tests Circadian Stimulus calculations
  - Verifies exponential model: CS = CS_max × (1 - exp(-a × melanopic_EDI))
  - Tests parameter fitting and clamping

- **MSI Model Tests** (`test/core/msi_model_test.dart`)
  - Tests Melatonin Suppression Index calculations
  - Verifies exponential model: MSI = 1 - exp(-k × X)
  - Tests dose calculation and parameter fitting

- **Melanopic Calculator Tests** (`test/core/melanopic_calculator_test.dart`)
  - Tests melanopic EDI calculations from lux values
  - Verifies light type ratios (warm LED, cool LED, etc.)
  - Tests screen contribution to total lux

- **PRC Model Tests** (`test/core/prc_model_test.dart`)
  - Tests Phase Response Curve calculations
  - Verifies morning advance and evening delay effects
  - Tests cumulative phase shift calculations

- **Integration Tests** (`test/integration/processing_pipeline_test.dart`)
  - Tests the full processing pipeline
  - Verifies end-to-end calculations from samples to results

## In-App Verification

The **Details** tab in the Results screen includes a **Calculation Verification** card that shows:

1. **Total Dose (X)** - Sum of CS × Δt values
2. **MSI Calculation** - Shows the formula and calculated value
3. **Average CS** - Mean of all CS values
4. **Average Melanopic Lux** - Mean of melanopic values

Each calculation shows:
- The formula used
- The calculated value
- A checkmark if the calculation matches expected values

## Manual Verification Steps

### 1. Verify Dose Calculation

The total dose X should equal:
```
X = Σ (CS_i × Δt)
```

Where:
- CS_i = Circadian Stimulus at time point i
- Δt = time interval in hours (duration / number of samples)

### 2. Verify MSI Calculation

MSI should be calculated as:
```
MSI = 1 - exp(-k × X)
```

Where:
- k = 0.25 (sensitivity constant)
- X = total dose in CS·hours

### 3. Verify CS Calculation

For each sample, CS should be:
```
CS = CS_max × (1 - exp(-a × melanopic_EDI))
```

Where:
- CS_max = 0.7
- a = 0.005
- melanopic_EDI = total_lux × melanopic_ratio

### 4. Verify Melanopic EDI

Melanopic EDI should be:
```
melanopic_EDI = total_lux × ratio
```

Where ratio depends on light type:
- Warm LED (2700K): 0.45
- Neutral LED (4000K): 0.60
- Cool LED (5000K): 0.85
- Daylight (6500K): 0.95

## Known Test Cases

### Test Case 1: Simple Constant Light

**Input:**
- 100 lux ambient light
- Neutral LED (4000K) - ratio 0.60
- 60 samples, 1 hour duration

**Expected:**
- Melanopic EDI: 60 lux
- CS: ~0.18 (0.7 × (1 - exp(-0.005 × 60)))
- Dose: ~0.18 CS·h
- MSI: ~0.044 (1 - exp(-0.25 × 0.18))

### Test Case 2: High Intensity Light

**Input:**
- 1000 lux ambient light
- Cool LED (5000K) - ratio 0.85
- 60 samples, 1 hour duration

**Expected:**
- Melanopic EDI: 850 lux
- CS: ~0.65 (approaching CS_max)
- Dose: ~0.65 CS·h
- MSI: ~0.15 (1 - exp(-0.25 × 0.65))

## Exporting Data for External Verification

You can export the raw data as CSV from the Results screen:
1. Tap the download icon in the app bar
2. The CSV file includes: timestamp, lux, melanopic, cs
3. Import into Excel/Python/R for independent verification

## Troubleshooting

If calculations don't match:

1. **Check time intervals**: Ensure Δt is calculated correctly
2. **Verify light type**: Check that the correct melanopic ratio is used
3. **Check for sleep episodes**: Sleep detection may attenuate lux values
4. **Verify model parameters**: k=0.25, a=0.005, CS_max=0.7

## References

- Rea et al. - Circadian Stimulus model
- CIE S 026:2018 - Melanopic weighting
- Khalsa et al. - Phase Response Curve

