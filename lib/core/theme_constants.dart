import 'package:flutter/material.dart';

class ThemeConstants {
  // readable names for theme keys
  static const Map<String, String> themeNames = {
    'system': 'System Default',
    'light': 'Light',
    'dark': 'Dark',
    'sepia': 'Sepia (Warm)',
    'blue': 'Cool Blue',
  };

  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primarySwatch: Colors.deepPurple,
    scaffoldBackgroundColor: Colors.white,
    visualDensity: VisualDensity.adaptivePlatformDensity,
  );

  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primarySwatch: Colors.deepPurple,
    scaffoldBackgroundColor: Colors.black,
  );

  static final ThemeData sepiaTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: const Color(0xFF7B5E3B),
    colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.brown)
        .copyWith(secondary: const Color(0xFFB98E66)),
    scaffoldBackgroundColor: const Color(0xFFF4E9DE),
  );

  static final ThemeData blueTheme = ThemeData(
    brightness: Brightness.light,
    primarySwatch: Colors.blue,
    scaffoldBackgroundColor: Colors.blue.shade50,
  );
}
