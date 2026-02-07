// lib/ui/screens/simulation_screen.dart
//
// Simple UI to run "what-if" simulations from an existing ResultsModel.

import 'package:flutter/material.dart';
import '../../models/results_model.dart';
import '../../models/simulation_scenario.dart';
import '../../models/chrono_plan.dart';
import '../../services/simulation_service.dart';
import '../../services/therapy_planner.dart';
import 'results_screen.dart';

class SimulationScreen extends StatefulWidget {
  final ResultsModel baseResults;

  const SimulationScreen({
    Key? key,
    required this.baseResults,
  }) : super(key: key);

  @override
  State<SimulationScreen> createState() => _SimulationScreenState();
}

class _SimulationScreenState extends State<SimulationScreen> {
  final _formKey = GlobalKey<FormState>();

  double _percentChange = -50.0;
  int _startHour = 19;
  int _endHour = 23;

  bool _addMorningBlock = false;
  int _morningHour = 8;
  int _morningMinutes = 30;

  ResultsModel? _simulatedResults;
  ChronoPlan? _plan;

  final _simulationService = SimulationService();
  final _planner = const TherapyPlanner();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Simulation & Plan'),
        backgroundColor: Colors.deepPurple,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text(
                'Configure Scenario',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _buildPercentSlider(),
              const SizedBox(height: 12),
              _buildWindowPickers(),
              const SizedBox(height: 12),
              _buildMorningBlockSection(),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _runSimulation,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Run Simulation'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
              const SizedBox(height: 24),
              if (_simulatedResults != null && _plan != null) ...[
                const Divider(),
                const SizedBox(height: 12),
                _buildPlanPreview(),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pushNamed(
                      '/results',
                      arguments: _simulatedResults!,
                    );
                  },
                  icon: const Icon(Icons.bar_chart),
                  label: const Text('View Simulated Charts'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPercentSlider() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Change exposure in selected window',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '${_percentChange.toStringAsFixed(0)}% '
              '${_percentChange < 0 ? 'less' : 'more'} circadian light',
            ),
            Slider(
              value: _percentChange,
              min: -100,
              max: 100,
              divisions: 40,
              label: '${_percentChange.toStringAsFixed(0)}%',
              onChanged: (v) {
                setState(() {
                  _percentChange = v;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWindowPickers() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Affected time window (hour of day)',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildHourDropdown(
                    label: 'From',
                    value: _startHour,
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() => _startHour = v);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildHourDropdown(
                    label: 'To',
                    value: _endHour,
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() => _endHour = v);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'For example, 19 → 23 means 7 PM to 11 PM. '
              'If end is earlier than start, the window wraps over midnight.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHourDropdown({
    required String label,
    required int value,
    required ValueChanged<int?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        DropdownButton<int>(
          value: value,
          isExpanded: true,
          items: List.generate(
            24,
            (i) => DropdownMenuItem(
              value: i,
              child: Text('${i.toString().padLeft(2, '0')}:00'),
            ),
          ),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildMorningBlockSection() {
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
                  'Add morning bright light block',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Switch(
                  value: _addMorningBlock,
                  onChanged: (v) {
                    setState(() => _addMorningBlock = v);
                  },
                ),
              ],
            ),
            if (_addMorningBlock) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildHourDropdown(
                      label: 'Start at',
                      value: _morningHour,
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() => _morningHour = v);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Duration (min)',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        DropdownButton<int>(
                          value: _morningMinutes,
                          isExpanded: true,
                          items: const [
                            DropdownMenuItem(value: 10, child: Text('10')),
                            DropdownMenuItem(value: 20, child: Text('20')),
                            DropdownMenuItem(value: 30, child: Text('30')),
                            DropdownMenuItem(value: 45, child: Text('45')),
                            DropdownMenuItem(value: 60, child: Text('60')),
                          ],
                          onChanged: (v) {
                            if (v == null) return;
                            setState(() => _morningMinutes = v);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _runSimulation() {
    final scenario = SimulationScenario(
      baseSessionId: widget.baseResults.sessionId,
      name: '$_percentChange% in $_startHour–$_endHour'
          '${_addMorningBlock ? ' + morning block' : ''}',
      exposureChangePercent: _percentChange,
      windowStartHour: _startHour,
      windowEndHour: _endHour,
      extraBlockMinutes: _addMorningBlock ? _morningMinutes : 0,
      extraBlockStartHour: _addMorningBlock ? _morningHour : null,
    );

    final simResults = _simulationService.simulate(
      base: widget.baseResults,
      scenario: scenario,
    );
    final plan = _planner.generatePlan(simResults);

    setState(() {
      _simulatedResults = simResults;
      _plan = plan;
    });
  }

  Widget _buildPlanPreview() {
    final plan = _plan!;
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              plan.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              plan.description,
              style: const TextStyle(fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 16),
            _planRow('Morning Light', plan.morningLightBlock),
            const SizedBox(height: 8),
            _planRow('Evening Dim Zone', plan.eveningDimBlock),
            const SizedBox(height: 8),
            _planRow('Bedtime Target', plan.idealBedtime),
            const SizedBox(height: 8),
            _planRow('Screen Use', plan.screenGuidance),
            const SizedBox(height: 8),
            _planRow('Recovery Timeline', plan.recoveryTimeline),
          ],
        ),
      ),
    );
  }

  Widget _planRow(String label, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 13, height: 1.5),
          ),
        ),
      ],
    );
  }
}


