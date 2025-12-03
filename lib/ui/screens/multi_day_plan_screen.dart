// lib/ui/screens/multi_day_plan_screen.dart
//
// Displays a multi-day chronotherapy plan built from multiple ResultsModel entries.

import 'package:flutter/material.dart';
import '../../models/chrono_plan.dart';

class MultiDayPlanScreen extends StatelessWidget {
  final ChronoPlan plan;

  const MultiDayPlanScreen({
    Key? key,
    required this.plan,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Multi-day Chronotherapy Plan'),
        backgroundColor: Colors.deepPurple,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              plan.title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              plan.description,
              style: const TextStyle(fontSize: 14, height: 1.6),
            ),
            const SizedBox(height: 20),
            _section('Morning Light', plan.morningLightBlock),
            const SizedBox(height: 12),
            _section('Evening Dim Zone', plan.eveningDimBlock),
            const SizedBox(height: 12),
            _section('Bedtime & Wake Time', plan.idealBedtime),
            const SizedBox(height: 12),
            _section('Screen Use', plan.screenGuidance),
            const SizedBox(height: 12),
            _section('Recovery Timeline', plan.recoveryTimeline),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, String body) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              body,
              style: const TextStyle(fontSize: 13, height: 1.6),
            ),
          ],
        ),
      ),
    );
  }
}


