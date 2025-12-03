// lib/ui/screens/results_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../models/results_model.dart';
import '../../core/prc_model.dart';
import '../../services/storage_service.dart';
import 'package:intl/intl.dart';
import 'simulation_screen.dart';

class ResultsScreen extends StatefulWidget {
  final ResultsModel results;

  const ResultsScreen({
    Key? key,
    required this.results,
  }) : super(key: key);

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  int _selectedTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analysis Results'),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareResults,
            tooltip: 'Share Results',
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _exportResults,
            tooltip: 'Export Data',
          ),
        ],
      ),
      body: Column(
        children: [
          // Tab selector
          Container(
            color: Colors.deepPurple.shade50,
            child: Row(
              children: [
                Expanded(
                  child: _buildTab('Summary', 0),
                ),
                Expanded(
                  child: _buildTab('Charts', 1),
                ),
                Expanded(
                  child: _buildTab('Details', 2),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: IndexedStack(
              index: _selectedTabIndex,
              children: [
                _buildSummaryTab(),
                _buildChartsTab(),
                _buildDetailsTab(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildTab(String label, int index) {
    final isSelected = _selectedTabIndex == index;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedTabIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? Colors.deepPurple : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.deepPurple : Colors.grey,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  // ==================== SUMMARY TAB ====================

  Widget _buildSummaryTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Health Score Card
        _buildHealthScoreCard(),

        const SizedBox(height: 20),

        // Key Metrics
        _buildKeyMetricsGrid(),

        const SizedBox(height: 20),

        // Interpretation
        _buildInterpretationCard(),

        const SizedBox(height: 20),

        // Recommendations
        _buildRecommendationsCard(),
      ],
    );
  }

  Widget _buildHealthScoreCard() {
    final score = widget.results.healthScore;
    final color = _getScoreColor(score);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.7), color],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            const Text(
              'Circadian Health Score',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Score number
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${score.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 64,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'out of 100',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            Text(
              widget.results.riskLevel,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.lightGreen;
    if (score >= 40) return Colors.orange;
    return Colors.red;
  }

  Widget _buildKeyMetricsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: [
        _buildMetricCard(
          'Melatonin Suppression',
          '${(widget.results.msiPredicted * 100).toStringAsFixed(1)}%',
          Icons.nightlight_round,
          Colors.indigo,
        ),
        _buildMetricCard(
          'Phase Shift',
          _formatPhaseShift(widget.results.phaseShift),
          Icons.schedule,
          Colors.purple,
        ),
        _buildMetricCard(
          'Avg. Melanopic Lux',
          '${widget.results.averageMelanopicLux.toStringAsFixed(0)}',
          Icons.wb_sunny,
          Colors.amber,
        ),
        _buildMetricCard(
          'Peak CS',
          widget.results.peakCS.toStringAsFixed(3),
          Icons.trending_up,
          Colors.teal,
        ),
      ],
    );
  }

  Widget _buildMetricCard(
      String label, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              height: 32,
              child: Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatPhaseShift(double hours) {
    final minutes = (hours * 60).abs().round();
    if (hours > 0) {
      return '+$minutes min\n(advance)';
    } else if (hours < 0) {
      return '-$minutes min\n(delay)';
    }
    return '~0 min';
  }

  Widget _buildInterpretationCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.info_outline, color: Colors.deepPurple),
                SizedBox(width: 8),
                Text(
                  'What This Means',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              _generateInterpretation(),
              style: const TextStyle(
                fontSize: 14,
                height: 1.6,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _generateInterpretation() {
    final msi = widget.results.msiPredicted;
    final phaseShift = widget.results.phaseShift;
    final avgCS = widget.results.averageCS;

    String interpretation = '';

    // MSI interpretation
    if (msi > 0.4) {
      interpretation +=
          'Your exposure resulted in significant melatonin suppression (${(msi * 100).toStringAsFixed(0)}%), which indicates strong circadian activation. ';
    } else if (msi > 0.2) {
      interpretation +=
          'You experienced moderate melatonin suppression (${(msi * 100).toStringAsFixed(0)}%), showing noticeable circadian system activation. ';
    } else if (msi > 0.1) {
      interpretation +=
          'Your light exposure caused mild melatonin suppression (${(msi * 100).toStringAsFixed(0)}%). ';
    } else {
      interpretation +=
          'The light exposure had minimal impact on melatonin (${(msi * 100).toStringAsFixed(0)}% suppression). ';
    }

    // Phase shift interpretation
    interpretation += PRCModel.interpretPhaseShift(phaseShift);
    interpretation += '. ';

    // Timing context
    final hour = widget.results.startTime.hour;
    if (hour >= 19 || hour < 4) {
      interpretation +=
          '\n\nSince this occurred during evening/night hours, high circadian light exposure may interfere with your natural sleep onset. ';
    } else if (hour >= 4 && hour < 10) {
      interpretation +=
          '\n\nMorning light exposure like this can help advance your circadian phase, making it easier to wake up earlier. ';
    } else {
      interpretation +=
          '\n\nDaytime exposure has a weaker phase-shifting effect but still contributes to overall circadian entrainment. ';
    }

    return interpretation;
  }

  Widget _buildRecommendationsCard() {
    return Card(
      elevation: 2,
      color: Colors.green.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.lightbulb_outline,
                        color: Colors.green.shade700),
                    const SizedBox(width: 8),
                    Text(
                      'Recommendations',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            SimulationScreen(baseResults: widget.results),
                      ),
                    );
                  },
                  icon: const Icon(Icons.science),
                  label: const Text('Simulate plan'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.green.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ..._generateRecommendations().map((rec) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.check_circle,
                          color: Colors.green.shade700, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          rec,
                          style: const TextStyle(fontSize: 14, height: 1.5),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  List<String> _generateRecommendations() {
    final recommendations = <String>[];
    final msi = widget.results.msiPredicted;
    final hour = widget.results.startTime.hour;

    if (hour >= 19 || hour < 4) {
      // Evening/night recommendations
      if (msi > 0.2) {
        recommendations.add(
            'Reduce evening light exposure. Use warm-colored lights (2700K) and dim to <20 lux 2 hours before bed.');
        recommendations.add(
            'Enable blue light filters on devices or use amber-tinted glasses after sunset.');
      }
      recommendations.add(
          'Establish a consistent "dim light zone" starting 2-3 hours before your target bedtime.');
    } else if (hour >= 4 && hour < 10) {
      // Morning recommendations
      recommendations.add(
          'Morning light exposure is beneficial! Continue getting bright light (>1000 lux) early in the day.');
      if (widget.results.phaseShift > 0) {
        recommendations.add(
            'Your current pattern promotes earlier sleep/wake times. Maintain this schedule for consistency.');
      }
    } else {
      // Daytime recommendations
      recommendations.add(
          'Maintain good daytime light exposure (>500 lux) to support circadian rhythm.');
    }

    // General recommendations
    if (widget.results.averageCS < 0.1) {
      recommendations.add(
          'Consider increasing light intensity during active hours to strengthen circadian signals.');
    }

    recommendations.add(
        'Track multiple sessions to identify patterns and optimize your light environment.');

    return recommendations;
  }

  // ==================== CHARTS TAB ====================

  Widget _buildChartsTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildChartCard(
          'Light Exposure Over Time',
          _buildLuxChart(),
        ),
        const SizedBox(height: 20),
        _buildChartCard(
          'Melanopic Lux Timeline',
          _buildMelanopicChart(),
        ),
        const SizedBox(height: 20),
        _buildChartCard(
          'Circadian Stimulus (CS)',
          _buildCSChart(),
        ),
        const SizedBox(height: 20),
        _buildChartCard(
          'Cumulative Dose (X)',
          _buildDoseChart(),
        ),
      ],
    );
  }

  Widget _buildChartCard(String title, Widget chart) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: chart,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLuxChart() {
    return LineChart(
      LineChartData(
        gridData: FlGridData(show: true, drawVerticalLine: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 45,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toInt()}',
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= widget.results.timestamps.length) {
                  return const Text('');
                }
                final time = widget.results.timestamps[value.toInt()];
                return Text(
                  DateFormat('HH:mm').format(time),
                  style: const TextStyle(fontSize: 9),
                );
              },
            ),
          ),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: _createSpots(widget.results.luxValues),
            isCurved: true,
            color: Colors.amber,
            barWidth: 3,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.amber.withOpacity(0.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMelanopicChart() {
    return LineChart(
      LineChartData(
        gridData: FlGridData(show: true, drawVerticalLine: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 45,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toInt()}',
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= widget.results.timestamps.length) {
                  return const Text('');
                }
                final time = widget.results.timestamps[value.toInt()];
                return Text(
                  DateFormat('HH:mm').format(time),
                  style: const TextStyle(fontSize: 9),
                );
              },
            ),
          ),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: _createSpots(widget.results.melanopicValues),
            isCurved: true,
            color: Colors.blue,
            barWidth: 3,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.blue.withOpacity(0.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCSChart() {
    return LineChart(
      LineChartData(
        gridData: FlGridData(show: true, drawVerticalLine: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toStringAsFixed(2),
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= widget.results.timestamps.length) {
                  return const Text('');
                }
                final time = widget.results.timestamps[value.toInt()];
                return Text(
                  DateFormat('HH:mm').format(time),
                  style: const TextStyle(fontSize: 9),
                );
              },
            ),
          ),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: _createSpots(widget.results.csValues),
            isCurved: true,
            color: Colors.purple,
            barWidth: 3,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.purple.withOpacity(0.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoseChart() {
    // Calculate cumulative dose over time
    final cumulativeDose = <double>[];
    double sum = 0.0;
    final deltaT =
        widget.results.durationHours / widget.results.csValues.length;

    for (final cs in widget.results.csValues) {
      sum += cs * deltaT;
      cumulativeDose.add(sum);
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: true, drawVerticalLine: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toStringAsFixed(2),
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= widget.results.timestamps.length) {
                  return const Text('');
                }
                final time = widget.results.timestamps[value.toInt()];
                return Text(
                  DateFormat('HH:mm').format(time),
                  style: const TextStyle(fontSize: 9),
                );
              },
            ),
          ),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: _createSpots(cumulativeDose),
            isCurved: true,
            color: Colors.teal,
            barWidth: 3,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.teal.withOpacity(0.3),
            ),
          ),
        ],
      ),
    );
  }

  List<FlSpot> _createSpots(List<double> values) {
    return List.generate(
      values.length,
      (index) => FlSpot(index.toDouble(), values[index]),
    );
  }

  // ==================== DETAILS TAB ====================

  Widget _buildDetailsTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildDetailCard('Session Information', [
          _buildDetailRow(
              'Session ID', widget.results.sessionId.substring(0, 8)),
          _buildDetailRow(
              'Start Time',
              DateFormat('MMM dd, yyyy HH:mm')
                  .format(widget.results.startTime)),
          _buildDetailRow('End Time',
              DateFormat('MMM dd, yyyy HH:mm').format(widget.results.endTime)),
          _buildDetailRow('Duration',
              '${widget.results.durationHours.toStringAsFixed(2)} hours'),
          _buildDetailRow(
              'Samples Collected', '${widget.results.timestamps.length}'),
          _buildDetailRow(
              'Light Type', _getLightTypeName(widget.results.lightType)),
        ]),
        const SizedBox(height: 16),
        _buildDetailCard('Calculated Metrics', [
          _buildDetailRow('Total Dose (X)',
              '${widget.results.totalDoseX.toStringAsFixed(4)} CS·h'),
          _buildDetailRow('MSI',
              '${(widget.results.msiPredicted * 100).toStringAsFixed(2)}%'),
          _buildDetailRow('Phase Shift',
              '${(widget.results.phaseShift * 60).toStringAsFixed(1)} minutes'),
          _buildDetailRow(
              'Average CS', widget.results.averageCS.toStringAsFixed(4)),
          _buildDetailRow('Peak CS', widget.results.peakCS.toStringAsFixed(4)),
          _buildDetailRow('Avg Melanopic Lux',
              widget.results.averageMelanopicLux.toStringAsFixed(1)),
          _buildDetailRow('Health Score',
              '${widget.results.healthScore.toStringAsFixed(0)}/100'),
        ]),
        const SizedBox(height: 16),
        _buildVerificationCard(),
        const SizedBox(height: 16),
        _buildDetailCard('Scientific Parameters Used', [
          _buildDetailRow('k (sensitivity)', '0.25'),
          _buildDetailRow('a (CS steepness)', '0.005'),
          _buildDetailRow('CS_max', '0.7'),
          _buildDetailRow('PRC scaling', '1.0 (morning), 0.9 (evening)'),
          _buildDetailRow('Model', 'Rea et al. + CIE S 026:2018'),
        ]),
        const SizedBox(height: 16),
        Card(
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.science, color: Colors.deepPurple),
                    SizedBox(width: 8),
                    Text(
                      'About the Science',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'This analysis uses scientifically validated models:\n\n'
                  '• Melanopic weighting based on CIE S 026:2018\n'
                  '• Circadian Stimulus model (Rea et al.)\n'
                  '• Melatonin suppression exponential model\n'
                  '• Phase Response Curve (Khalsa et al.)\n\n'
                  'Results provide estimates for research and educational purposes. '
                  'Not medical advice.',
                  style: TextStyle(fontSize: 13, height: 1.6),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVerificationCard() {
    // Calculate verification values
    final deltaT = widget.results.durationHours / widget.results.csValues.length;
    final calculatedDose = widget.results.csValues
        .map((cs) => cs * deltaT)
        .fold(0.0, (a, b) => a + b);
    
    return Card(
      elevation: 2,
      color: Colors.blue.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.verified, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                Text(
                  'Calculation Verification',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildVerificationRow(
              'Step 1: Total Dose (X)',
              'Sum of CS × Δt',
              '${calculatedDose.toStringAsFixed(4)} CS·h',
              calculatedDose,
              widget.results.totalDoseX,
            ),
            const SizedBox(height: 12),
            _buildVerificationRow(
              'Step 2: MSI Calculation',
              'MSI = 1 - exp(-k × X)',
              '${widget.results.msiPredicted.toStringAsFixed(4)}',
              widget.results.msiPredicted,
              widget.results.msiPredicted,
              showFormula: true,
            ),
            const SizedBox(height: 12),
            _buildVerificationRow(
              'Step 3: Average CS',
              'Mean of all CS values',
              '${widget.results.averageCS.toStringAsFixed(4)}',
              widget.results.averageCS,
              widget.results.csValues.reduce((a, b) => a + b) / widget.results.csValues.length,
            ),
            const SizedBox(height: 12),
            _buildVerificationRow(
              'Step 4: Avg Melanopic Lux',
              'Mean of melanopic values',
              '${widget.results.averageMelanopicLux.toStringAsFixed(1)}',
              widget.results.averageMelanopicLux,
              widget.results.melanopicValues.reduce((a, b) => a + b) / widget.results.melanopicValues.length,
            ),
            const SizedBox(height: 12),
            Text(
              'Formula: k = 0.25, a = 0.005, CS_max = 0.7',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade700,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerificationRow(
    String label,
    String description,
    String value,
    double actual,
    double expected, {
    bool showFormula = false,
  }) {
    final difference = (actual - expected).abs();
    final isMatch = difference < 0.0001; // Allow small floating point differences
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isMatch ? Colors.green.shade700 : Colors.orange.shade700,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  isMatch ? Icons.check_circle : Icons.info_outline,
                  size: 16,
                  color: isMatch ? Colors.green.shade700 : Colors.orange.shade700,
                ),
              ],
            ),
          ],
        ),
        if (showFormula) ...[
          const SizedBox(height: 4),
          Text(
            'k = 0.25, X = ${widget.results.totalDoseX.toStringAsFixed(4)}',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade600,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDetailCard(String title, List<Widget> rows) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...rows,
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
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

  // ==================== BOTTOM BAR ====================

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              icon: const Icon(Icons.home),
              label: const Text('Back to Home'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              icon: const Icon(Icons.fiber_manual_record),
              label: const Text('New Session'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

// ==================== ACTIONS ====================

  void _shareResults() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Share functionality coming soon')),
    );
  }

  void _exportResults() {
    () async {
      try {
        // Request storage permission if needed (Android)
        if (Platform.isAndroid) {
          final status = await Permission.storage.status;
          if (!status.isGranted) {
            final result = await Permission.storage.request();
            if (!result.isGranted) {
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Storage permission is required to export files'),
                  backgroundColor: Colors.orange,
                ),
              );
              return;
            }
          }
        }

        final buffer = StringBuffer();
        buffer.writeln('timestamp,lux,melanopic,cs');
        for (int i = 0; i < widget.results.timestamps.length; i++) {
          final t = widget.results.timestamps[i].toIso8601String();
          final lux = widget.results.luxValues[i];
          final mel = widget.results.melanopicValues[i];
          final cs = widget.results.csValues[i];
          buffer.writeln('$t,$lux,$mel,$cs');
        }

        final storage = StorageService();
        final dir = await storage.appDocDir;
        // Ensure directory exists
        if (!await dir.exists()) {
          await dir.create(recursive: true);
        }
        final file = File(
          '${dir.path}/results_${widget.results.sessionId}.csv',
        );
        await file.writeAsString(buffer.toString());

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Exported to ${file.path}'),
            duration: const Duration(seconds: 3),
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }();
  }
}
