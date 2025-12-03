// lib/ui/screens/debug_verification_screen.dart

import 'package:flutter/material.dart';
import '../../core/cs_model.dart';
import '../../core/msi_model.dart';
import '../../core/melanopic_calculator.dart';
import '../../core/prc_model.dart';
import '../../utils/constants.dart';
import '../../models/light_sample.dart';

class DebugVerificationScreen extends StatefulWidget {
  const DebugVerificationScreen({Key? key}) : super(key: key);

  @override
  State<DebugVerificationScreen> createState() => _DebugVerificationScreenState();
}

class _DebugVerificationScreenState extends State<DebugVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Input fields
  final _luxController = TextEditingController(text: '100');
  final _durationController = TextEditingController(text: '1.0');
  final _numSamplesController = TextEditingController(text: '60');
  String _selectedLightType = 'neutral_led_4000k';
  int _startHour = 8;
  bool _screenOn = false;
  final _screenBrightnessController = TextEditingController(text: '0.5');
  
  // Calculated results
  double? _melanopicEDI;
  double? _cs;
  double? _doseX;
  double? _msi;
  double? _phaseShift;
  String? _calculationSteps;

  @override
  void dispose() {
    _luxController.dispose();
    _durationController.dispose();
    _numSamplesController.dispose();
    _screenBrightnessController.dispose();
    super.dispose();
  }

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      final lux = double.parse(_luxController.text);
      final durationHours = double.parse(_durationController.text);
      final screenBrightness = _screenOn 
          ? double.tryParse(_screenBrightnessController.text) ?? 0.5
          : null;

      // Step 1: Calculate total lux at eye
      final sample = LightSample(
        timestamp: DateTime(2024, 1, 1, _startHour, 0),
        ambientLux: lux,
        screenOn: _screenOn,
        screenBrightness: screenBrightness,
      );
      
      final totalLux = MelanopicCalculator.calculateTotalLuxAtEye(sample);
      
      // Step 2: Calculate melanopic EDI
      final melanopicEDI = MelanopicCalculator.calculateMelanopicEDI(
        totalLux: totalLux,
        lightType: _selectedLightType,
      );
      _melanopicEDI = melanopicEDI;
      
      // Step 3: Calculate CS
      const csModel = CSModel();
      final cs = csModel.calculateCS(melanopicEDI);
      _cs = cs;
      
      // Step 4: Calculate dose (CS × duration)
      _doseX = cs * durationHours;
      
      // Step 5: Calculate MSI
      const msiModel = MSIModel();
      final doseX = _doseX!;
      _msi = msiModel.calculateMSI(doseX);
      
      // Step 6: Calculate phase shift
      final exposureTime = DateTime(2024, 1, 1, _startHour, 0);
      _phaseShift = PRCModel.calculatePhaseShift(
        time: exposureTime,
        doseX: doseX,
      );
      
      // Build calculation steps string
      final ratio = CircadianConstants.melanopicRatios[_selectedLightType] ?? 0.6;
      final buffer = StringBuffer();
      buffer.writeln('Step 1: Total Lux at Eye');
      buffer.writeln('  Ambient Lux: ${lux.toStringAsFixed(1)}');
      if (_screenOn && screenBrightness != null) {
        final screenLux = MelanopicCalculator.estimateScreenLux(screenBrightness);
        buffer.writeln('  Screen Lux: ${screenLux.toStringAsFixed(1)}');
        buffer.writeln('  Total Lux: ${totalLux.toStringAsFixed(1)}');
      } else {
        buffer.writeln('  Screen: Off');
        buffer.writeln('  Total Lux: ${totalLux.toStringAsFixed(1)}');
      }
      buffer.writeln('');
      buffer.writeln('Step 2: Melanopic EDI');
      buffer.writeln('  Formula: melanopic_EDI = total_lux × ratio');
      buffer.writeln('  Ratio (${_getLightTypeName(_selectedLightType)}): ${ratio.toStringAsFixed(2)}');
      buffer.writeln('  melanopic_EDI = ${totalLux.toStringAsFixed(1)} × ${ratio.toStringAsFixed(2)}');
      buffer.writeln('  melanopic_EDI = ${melanopicEDI.toStringAsFixed(2)} lux');
      buffer.writeln('');
      buffer.writeln('Step 3: Circadian Stimulus (CS)');
      buffer.writeln('  Formula: CS = CS_max × (1 - exp(-a × melanopic_EDI))');
      buffer.writeln('  CS_max = ${CircadianConstants.csMax}');
      buffer.writeln('  a = ${CircadianConstants.aDefault}');
      buffer.writeln('  CS = ${CircadianConstants.csMax} × (1 - exp(-${CircadianConstants.aDefault} × ${melanopicEDI.toStringAsFixed(2)}))');
      buffer.writeln('  CS = ${cs.toStringAsFixed(4)}');
      buffer.writeln('');
      buffer.writeln('Step 4: Total Dose (X)');
      buffer.writeln('  Formula: X = CS × duration');
      buffer.writeln('  X = ${cs.toStringAsFixed(4)} × ${durationHours.toStringAsFixed(2)} hours');
      buffer.writeln('  X = ${doseX.toStringAsFixed(4)} CS·h');
      buffer.writeln('');
      buffer.writeln('Step 5: Melatonin Suppression Index (MSI)');
      buffer.writeln('  Formula: MSI = 1 - exp(-k × X)');
      buffer.writeln('  k = ${CircadianConstants.kDefault}');
      buffer.writeln('  MSI = 1 - exp(-${CircadianConstants.kDefault} × ${doseX.toStringAsFixed(4)})');
      final msi = _msi!;
      buffer.writeln('  MSI = ${msi.toStringAsFixed(4)} (${(msi * 100).toStringAsFixed(2)}%)');
      buffer.writeln('');
      buffer.writeln('Step 6: Phase Shift');
      buffer.writeln('  Formula: PhaseShift = PRC_weight(time) × scaling × X');
      final prcWeight = PRCModel.getPRCWeight(exposureTime);
      final scaling = _getScalingFactor(exposureTime);
      final phaseShift = _phaseShift!;
      buffer.writeln('  Time: ${_startHour.toString().padLeft(2, '0')}:00');
      buffer.writeln('  PRC Weight: ${prcWeight.toStringAsFixed(2)}');
      buffer.writeln('  Scaling Factor: ${scaling.toStringAsFixed(2)}');
      buffer.writeln('  PhaseShift = ${prcWeight.toStringAsFixed(2)} × ${scaling.toStringAsFixed(2)} × ${doseX.toStringAsFixed(4)}');
      buffer.writeln('  PhaseShift = ${phaseShift.toStringAsFixed(4)} hours');
      buffer.writeln('  PhaseShift = ${(phaseShift * 60).toStringAsFixed(1)} minutes');
      if (phaseShift > 0) {
        buffer.writeln('  Direction: Advance (earlier sleep/wake)');
      } else if (phaseShift < 0) {
        buffer.writeln('  Direction: Delay (later sleep/wake)');
      } else {
        buffer.writeln('  Direction: Minimal effect');
      }
      
      _calculationSteps = buffer.toString();
    });
  }

  double _getScalingFactor(DateTime time) {
    final hour = time.hour;
    if (hour >= 4 && hour < 10) {
      return CircadianConstants.scalingFactorMorning;
    } else if (hour >= 19 || hour < 1) {
      return CircadianConstants.scalingFactorEvening;
    }
    return 0.5;
  }

  String _getLightTypeName(String type) {
    final names = {
      'warm_led_2700k': 'Warm LED (2700K)',
      'neutral_led_4000k': 'Neutral LED (4000K)',
      'cool_led_5000k': 'Cool LED (5000K)',
      'daylight_6500k': 'Daylight (6500K)',
      'phone_screen': 'Phone Screen',
      'incandescent': 'Incandescent',
    };
    return names[type] ?? type;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug & Verification'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Input section
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.input, color: Colors.deepPurple),
                        SizedBox(width: 8),
                        Text(
                          'Input Parameters',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _luxController,
                      decoration: const InputDecoration(
                        labelText: 'Ambient Lux',
                        hintText: '100',
                        border: OutlineInputBorder(),
                        helperText: 'Photopic lux from light sensor',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter lux value';
                        }
                        final parsed = double.tryParse(value);
                        if (parsed == null || parsed < 0) {
                          return 'Please enter a valid positive number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedLightType,
                      decoration: const InputDecoration(
                        labelText: 'Light Type',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'warm_led_2700k',
                          child: Text('Warm LED (2700K)'),
                        ),
                        DropdownMenuItem(
                          value: 'neutral_led_4000k',
                          child: Text('Neutral LED (4000K)'),
                        ),
                        DropdownMenuItem(
                          value: 'cool_led_5000k',
                          child: Text('Cool LED (5000K)'),
                        ),
                        DropdownMenuItem(
                          value: 'daylight_6500k',
                          child: Text('Daylight (6500K)'),
                        ),
                        DropdownMenuItem(
                          value: 'phone_screen',
                          child: Text('Phone Screen'),
                        ),
                        DropdownMenuItem(
                          value: 'incandescent',
                          child: Text('Incandescent'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedLightType = value);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _durationController,
                            decoration: const InputDecoration(
                              labelText: 'Duration (hours)',
                              hintText: '1.0',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Required';
                              }
                              final parsed = double.tryParse(value);
                              if (parsed == null || parsed <= 0) {
                                return 'Must be > 0';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _numSamplesController,
                            decoration: const InputDecoration(
                              labelText: 'Number of Samples',
                              hintText: '60',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Required';
                              }
                              final parsed = int.tryParse(value);
                              if (parsed == null || parsed <= 0) {
                                return 'Must be > 0';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      initialValue: _startHour,
                      decoration: const InputDecoration(
                        labelText: 'Start Time (hour of day)',
                        border: OutlineInputBorder(),
                        helperText: 'Affects phase shift calculation',
                      ),
                      items: List.generate(
                        24,
                        (i) => DropdownMenuItem(
                          value: i,
                          child: Text('${i.toString().padLeft(2, '0')}:00'),
                        ),
                      ),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _startHour = value);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Screen On'),
                      subtitle: const Text('Include screen contribution'),
                      value: _screenOn,
                      onChanged: (value) {
                        setState(() => _screenOn = value);
                      },
                    ),
                    if (_screenOn) ...[
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _screenBrightnessController,
                        decoration: const InputDecoration(
                          labelText: 'Screen Brightness (0.0 - 1.0)',
                          hintText: '0.5',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (_screenOn) {
                            if (value == null || value.isEmpty) {
                              return 'Required when screen is on';
                            }
                            final parsed = double.tryParse(value);
                            if (parsed == null || parsed < 0 || parsed > 1) {
                              return 'Must be between 0.0 and 1.0';
                            }
                          }
                          return null;
                        },
                      ),
                    ],
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _calculate,
                        icon: const Icon(Icons.calculate),
                        label: const Text('Calculate'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Results section
            if (_melanopicEDI != null) ...[
              const SizedBox(height: 20),
              Card(
                elevation: 2,
                color: Colors.green.shade50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.calculate, color: Colors.green.shade700),
                          const SizedBox(width: 8),
                          Text(
                            'Calculation Results',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildResultRow('Melanopic EDI', '${_melanopicEDI!.toStringAsFixed(2)} lux'),
                      _buildResultRow('Circadian Stimulus (CS)', _cs!.toStringAsFixed(4)),
                      _buildResultRow('Total Dose (X)', '${_doseX!.toStringAsFixed(4)} CS·h'),
                      _buildResultRow('MSI', '${_msi!.toStringAsFixed(4)} (${(_msi! * 100).toStringAsFixed(2)}%)'),
                      _buildResultRow('Phase Shift', '${(_phaseShift! * 60).toStringAsFixed(1)} minutes'),
                      if (_phaseShift! > 0)
                        _buildResultRow('Direction', 'Advance (earlier sleep/wake)', isSubtext: true)
                      else if (_phaseShift! < 0)
                        _buildResultRow('Direction', 'Delay (later sleep/wake)', isSubtext: true),
                    ],
                  ),
                ),
              ),
            ],

            // Step-by-step calculation
            if (_calculationSteps != null) ...[
              const SizedBox(height: 20),
              Card(
                elevation: 2,
                color: Colors.blue.shade50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.list_alt, color: Colors.blue.shade700),
                          const SizedBox(width: 8),
                          Text(
                            'Step-by-Step Calculation',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: SelectableText(
                          _calculationSteps!,
                          style: const TextStyle(
                            fontSize: 12,
                            fontFamily: 'monospace',
                            height: 1.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultRow(String label, String value, {bool isSubtext = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isSubtext ? 13 : 14,
              fontWeight: isSubtext ? FontWeight.normal : FontWeight.w600,
              color: isSubtext ? Colors.grey.shade700 : Colors.black87,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isSubtext ? 13 : 14,
              fontWeight: FontWeight.bold,
              color: Colors.green.shade700,
            ),
          ),
        ],
      ),
    );
  }
}

