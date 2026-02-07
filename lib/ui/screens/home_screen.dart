// lib/ui/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'recording_screen.dart';
import 'history_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('ChronoSleep'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.deepPurple.shade700,
              Colors.deepPurple.shade400,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),

                // App icon/logo
                Icon(
                  Icons.light_mode,
                  size: 100,
                  color: Colors.white.withOpacity(0.9),
                ),

                const SizedBox(height: 20),

                // Title
                Text(
                  'Circadian Light\nAnalyzer',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),

                const SizedBox(height: 10),

                // Subtitle
                Text(
                  'Measure and analyze your light exposure\nfor better circadian health',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withOpacity(0.8),
                      ),
                ),

                const Spacer(),

                // Main action button
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/recording');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.deepPurple,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.fiber_manual_record, color: Colors.red),
                      SizedBox(width: 12),
                      Text(
                        'Start New Recording',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Secondary buttons
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, '/history');
                  },
                  icon: const Icon(Icons.history),
                  label: const Text('View Past Sessions'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white, width: 2),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, '/settings');
                  },
                  icon: const Icon(Icons.settings),
                  label: const Text('Settings & Calibration'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white, width: 2),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // Info card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.white.withOpacity(0.9),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap "Start New Recording" to begin measuring your light environment. '
                        'Keep your phone in typical viewing position for accurate results.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
