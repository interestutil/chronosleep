import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme_constants.dart';
import 'ui/settings_page.dart';
import 'ui/screens/home_screen.dart';
import 'ui/screens/recording_screen.dart';
import 'ui/screens/history_screen.dart';
import 'ui/screens/settings_screen.dart';
import 'ui/screens/processing_screen.dart';
import 'ui/screens/results_screen.dart';
import 'ui/screens/simulation_screen.dart';
import 'ui/screens/multi_day_plan_screen.dart';
import 'ui/screens/debug_verification_screen.dart';

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
  final GlobalKey<NavigatorState> _navKey = GlobalKey<NavigatorState>();

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
    final result = await _navKey.currentState?.push<String>(
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
      navigatorKey: _navKey,
      initialRoute: '/',
      routes: {
        '/': (ctx) => const HomeScreen(),
        '/home': (ctx) => const HomeScreen(),
        '/recording': (ctx) => const RecordingScreen(),
        '/history': (ctx) => const HistoryScreen(),
        '/settings': (ctx) => const SettingsScreen(),
        '/debug': (ctx) => const DebugVerificationScreen(),
      },
      onGenerateRoute: (settings) {
        final name = settings.name;
        final args = settings.arguments;

        switch (name) {
          case '/processing':
            if (args is Map && args['session'] != null && args['lightType'] != null) {
              return MaterialPageRoute(
                builder: (_) => ProcessingScreen(
                  session: args['session'],
                  lightType: args['lightType'],
                ),
              );
            }
            break;
          case '/results':
            if (args != null) {
              return MaterialPageRoute(
                builder: (_) => ResultsScreen(results: args as dynamic),
              );
            }
            break;
          case '/simulation':
            if (args is Map && args['baseResults'] != null) {
              return MaterialPageRoute(
                builder: (_) => SimulationScreen(baseResults: args['baseResults']),
              );
            }
            break;
          case '/multi_day_plan':
            if (args is Map && args['plan'] != null) {
              return MaterialPageRoute(
                builder: (_) => MultiDayPlanScreen(plan: args['plan']),
              );
            }
            break;
        }
        return null;
      },
      builder: (context, child) {
        // Wrap with Scaffold to keep the theme settings FAB available globally
        return Scaffold(
          body: child,
          floatingActionButton: FloatingActionButton(
            onPressed: _openSettings,
            child: const Icon(Icons.color_lens),
          ),
        );
      },
    );
  }
}

