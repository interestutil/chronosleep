// lib/ui/screens/processing_screen.dart

import 'package:flutter/material.dart';
import '../../models/session_data.dart';
import '../../services/processing_pipeline.dart';
import 'results_screen.dart';

class ProcessingScreen extends StatefulWidget {
  final SessionData session;
  final String lightType;

  const ProcessingScreen({
    Key? key,
    required this.session,
    required this.lightType,
  }) : super(key: key);

  @override
  State<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends State<ProcessingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _processSession();
  }

  Future<void> _processSession() async {
    try {
      // Add artificial delay for UX
      await Future.delayed(const Duration(seconds: 2));

      // Process the session
      final pipeline = ProcessingPipeline();
      final results = await pipeline.process(
        session: widget.session,
        lightType: widget.lightType,
      );

      // Navigate to results
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ResultsScreen(results: results),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Processing failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated icon
              RotationTransition(
                turns: _animationController,
                child: Icon(
                  Icons.psychology,
                  size: 100,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),

              const SizedBox(height: 40),

              const Text(
                'Analyzing your circadian\nlight exposure...',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 60),
                child: LinearProgressIndicator(
                  backgroundColor: Colors.white.withOpacity(0.3),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),

              const SizedBox(height: 30),

              Text(
                'Computing melanopic lux...\n'
                'Calculating circadian stimulus...\n'
                'Estimating melatonin suppression...\n'
                'Predicting phase shift...',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                  height: 1.8,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
