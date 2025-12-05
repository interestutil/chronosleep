// lib/ui/screens/settings_screen.dart
//
// Settings & calibration: adjust screen brightness-to-lux mapping and model parameters.

import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import 'debug_verification_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late Map<double, double> _brightnessToLux;
  double _k = CircadianConstants.kDefault;
  double _a = CircadianConstants.aDefault;
  bool _smoothingEnabled = CircadianConstants.sensorSmoothingEnabled;
  double _smoothingFactor = CircadianConstants.sensorSmoothingFactor;
  double _viewingDistanceCm = CircadianConstants.viewingDistanceCm;

  @override
  void initState() {
    super.initState();
    _brightnessToLux = Map.of(CircadianConstants.screenBrightnessToLux);
    _smoothingEnabled = CircadianConstants.sensorSmoothingEnabled;
    _smoothingFactor = CircadianConstants.sensorSmoothingFactor;
    _viewingDistanceCm = CircadianConstants.viewingDistanceCm;
  }

  void _save() {
    // Apply to global constants map (mutable)
    CircadianConstants.screenBrightnessToLux = Map.of(_brightnessToLux);
    CircadianConstants.sensorSmoothingEnabled = _smoothingEnabled;
    CircadianConstants.sensorSmoothingFactor = _smoothingFactor;
    CircadianConstants.viewingDistanceCm = _viewingDistanceCm;
    // For now, k and a are not fed back into models globally (would require refactoring),
    // but we keep them here to show intent and UI.

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Settings saved for this run'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings & Calibration'),
        backgroundColor: Colors.deepPurple,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildBrightnessSection(),
          const SizedBox(height: 20),
          _buildViewingDistanceSection(),
          const SizedBox(height: 20),
          _buildSensorSmoothingSection(),
          const SizedBox(height: 20),
          _buildModelParamsSection(),
          const SizedBox(height: 20),
          _buildDebugSection(),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text(
              'Save Settings',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrightnessSection() {
    final keys = _brightnessToLux.keys.toList()..sort();
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Screen Brightness Calibration',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Adjust the approximate lux at the eye for each brightness level.\n'
              'Use a lux meter or trusted reference, or leave defaults if unsure.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            ...keys.map((b) {
              final controller = TextEditingController(
                text: _brightnessToLux[b]!.toStringAsFixed(0),
              );
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 70,
                      child: Text(
                        '${(b * 100).round()}%',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: controller,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: false),
                        decoration: const InputDecoration(
                          labelText: 'Lux at eye',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        onChanged: (v) {
                          final parsed = double.tryParse(v);
                          if (parsed != null && parsed >= 0) {
                            _brightnessToLux[b] = parsed;
                          }
                        },
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildViewingDistanceSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Viewing Distance',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Distance from your eyes to the screen. Used to calculate accurate screen light contribution.\n'
              'Typical viewing distance: 30-40 cm.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Text(
              'Distance: ${_viewingDistanceCm.toStringAsFixed(0)} cm',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Slider(
              value: _viewingDistanceCm,
              min: 20.0,
              max: 60.0,
              divisions: 40,
              label: '${_viewingDistanceCm.toStringAsFixed(0)} cm',
              onChanged: (value) {
                setState(() {
                  _viewingDistanceCm = value;
                });
              },
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '20 cm\n(close)',
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                  textAlign: TextAlign.center,
                ),
                Text(
                  '60 cm\n(far)',
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSensorSmoothingSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Sensor Smoothing',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Switch(
                  value: _smoothingEnabled,
                  onChanged: (value) {
                    setState(() {
                      _smoothingEnabled = value;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Reduces sensor fluctuations using exponential moving average. '
              'Disable for raw sensor readings.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            if (_smoothingEnabled) ...[
              const SizedBox(height: 16),
              Text(
                'Smoothing Factor: ${(_smoothingFactor * 100).toStringAsFixed(0)}%',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Slider(
                value: _smoothingFactor,
                min: 0.1,
                max: 1.0,
                divisions: 9,
                label: '${(_smoothingFactor * 100).toStringAsFixed(0)}%',
                onChanged: (value) {
                  setState(() {
                    _smoothingFactor = value;
                  });
                },
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'More smoothing\n(less responsive)',
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    'Less smoothing\n(more responsive)',
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildModelParamsSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Model Parameters (Advanced)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'You can inspect the current values for k (sensitivity) and a (CS steepness). '
              'Changing them requires code changes in the model constructors.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            _paramRow('k (MSI sensitivity)', _k.toStringAsFixed(3)),
            const SizedBox(height: 8),
            _paramRow('a (CS steepness)', _a.toStringAsFixed(3)),
          ],
        ),
      ),
    );
  }

  Widget _paramRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildDebugSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Debug & Verification',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Manually input values and verify calculations step-by-step.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const DebugVerificationScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.bug_report),
                label: const Text('Open Debug & Verification'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


