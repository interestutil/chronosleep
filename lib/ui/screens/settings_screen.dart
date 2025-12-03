// lib/ui/screens/settings_screen.dart
//
// Settings & calibration: adjust screen brightness-to-lux mapping and model parameters.

import 'package:flutter/material.dart';
import '../../utils/constants.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late Map<double, double> _brightnessToLux;
  double _k = CircadianConstants.kDefault;
  double _a = CircadianConstants.aDefault;

  @override
  void initState() {
    super.initState();
    _brightnessToLux = Map.of(CircadianConstants.screenBrightnessToLux);
  }

  void _save() {
    // Apply to global constants map (mutable)
    CircadianConstants.screenBrightnessToLux = Map.of(_brightnessToLux);
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
          _buildModelParamsSection(),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
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
}


