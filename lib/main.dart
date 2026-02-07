import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme_constants.dart';
import 'ui/settings_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final saved = prefs.getString('app_theme') ?? 'system';
  runApp(MyApp(initialThemeKey: saved));
}

class MyApp extends StatefulWidget {
  final String initialThemeKey;
  const MyApp({Key? key, required this.initialThemeKey}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late String _themeKey;

  @override
  void initState() {
    super.initState();
    _themeKey = widget.initialThemeKey;
  }

  ThemeMode _modeForKey(String key) {
    switch (key) {
      case 'light':
      case 'sepia':
      case 'blue':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  ThemeData _themeForKey(String key) {
    switch (key) {
      case 'sepia':
        return ThemeConstants.sepiaTheme;
      case 'blue':
        return ThemeConstants.blueTheme;
      default:
        return ThemeConstants.lightTheme;
    }
  }

  void _openSettings() async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => SettingsPage(currentKey: _themeKey),
      ),
    );
    if (result != null && result != _themeKey) {
      setState(() => _themeKey = result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ChronoSleep',
      theme: _themeForKey(_themeKey),
      darkTheme: ThemeConstants.darkTheme,
      themeMode: _modeForKey(_themeKey),
      home: Scaffold(
        appBar: AppBar(title: const Text('ChronoSleep')),
        body: Center(child: const Text('Welcome to ChronoSleep')),
        floatingActionButton: FloatingActionButton(
          onPressed: _openSettings,
          child: const Icon(Icons.color_lens),
        ),
      ),
    );
  }
}

