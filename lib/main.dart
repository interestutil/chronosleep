import 'package:flutter/material.dart';
import 'ui/screens/home_screen.dart';

void main() {
  runApp(const ChronoSleepApp());
}

class ChronoSleepApp extends StatelessWidget {
  const ChronoSleepApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ChronoTherapy Analyzer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.deepPurple,
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const HomeScreen(),
    );
  }
}

