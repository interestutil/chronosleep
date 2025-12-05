// lib/ui/screens/recording_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import '../../services/recording_manager.dart';
import '../../services/sensor_service.dart';
import '../../services/storage_service.dart';
import '../../services/screen_brightness_tracker.dart';
import '../../services/foreground_service.dart';
import '../../core/melanopic_calculator.dart';
import '../../utils/constants.dart';
import 'processing_screen.dart';

class RecordingScreen extends StatefulWidget {
  const RecordingScreen({Key? key}) : super(key: key);

  @override
  State<RecordingScreen> createState() => _RecordingScreenState();
}

class _RecordingScreenState extends State<RecordingScreen> with WidgetsBindingObserver {
  late RecordingManager _recordingManager;
  late SensorService _sensorService;
  ScreenBrightnessTracker? _brightnessTracker;
  bool _isRecording = false;
  Duration _elapsedTime = Duration.zero;
  Timer? _timer;

  double _currentLux = 0.0;
  double _currentCS = 0.0;
  StreamSubscription? _sensorSubscription;

  String _selectedLightType = 'neutral_led_4000k';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeRecording();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    if (!_isRecording) return; // Only handle lifecycle during recording
    
    if (kDebugMode) {
      debugPrint('RecordingScreen: App lifecycle changed to: $state');
    }
    
    // Handle sensor pause/resume
    // NOTE: With foreground service active, sensors should continue in background
    // Only pause if foreground service is not active
    switch (state) {
      case AppLifecycleState.paused:
        // App going to background - only pause if no foreground service
        // The pause() method will check foreground service status internally
        _sensorService.pause();
        if (kDebugMode) {
          debugPrint('RecordingScreen: App paused - sensors may continue with foreground service');
        }
        break;
      case AppLifecycleState.inactive:
        // App is inactive (e.g., notification tray pulled down)
        // Don't pause sensors - this is temporary and sensors should continue
        if (kDebugMode) {
          debugPrint('RecordingScreen: App inactive (notification tray?) - keeping sensors active');
        }
        // Don't call pause() for inactive state - it's too aggressive
        break;
      case AppLifecycleState.resumed:
        // App coming to foreground - resume sensors (in case they were paused)
        _sensorService.resume();
        if (kDebugMode) {
          debugPrint('RecordingScreen: App resumed - sensors active');
        }
        break;
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        // App being terminated or hidden
        break;
    }
    
    // DON'T update screen state based on app lifecycle
    // The screen brightness tracker's periodic timer will handle screen state
    // The screen might still be on even when app is in background
    // Setting screen state to false when app goes to background would be incorrect
  }

  void _initializeRecording() {
    _sensorService = SensorService();
    final storageService = StorageService();

    // Create screen brightness tracker
    _brightnessTracker = ScreenBrightnessTracker(sensorService: _sensorService);

    _recordingManager = RecordingManager(
      sensorService: _sensorService,
      storage: storageService,
    );

    // Listen to sensor updates for real-time display
    _sensorSubscription = _sensorService.sampleStream.listen((sample) {
      if (mounted && _isRecording) {
        setState(() {
          // Calculate total lux including screen contribution (same as processing pipeline)
          final totalLux = MelanopicCalculator.calculateTotalLuxAtEye(sample);
          _currentLux = totalLux;
          
          // Calculate CS using total lux (includes screen contribution)
          final melanopicRatio =
              CircadianConstants.melanopicRatios[_selectedLightType] ?? 0.6;
          final melanopicLux = totalLux * melanopicRatio;
          _currentCS = (melanopicLux / 1000.0).clamp(0.0, 0.7);
        });
      }
    });
  }

  void _startRecording() async {
    try {
      // Start foreground service to keep sensors running in background
      if (kDebugMode) {
        debugPrint('RecordingScreen: Starting foreground service...');
      }
      final serviceStarted = await ForegroundService.start();
      if (kDebugMode) {
        debugPrint('RecordingScreen: Foreground service started: $serviceStarted');
      }
      
      if (serviceStarted) {
        _sensorService.setForegroundServiceActive(true);
        if (kDebugMode) {
          debugPrint('RecordingScreen: Sensor service notified of foreground service');
        }
      } else {
        if (kDebugMode) {
          debugPrint('RecordingScreen: WARNING - Foreground service failed to start');
        }
        // Show warning to user
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Warning: Background recording may not work. Check notification permission.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
      
      // Start screen brightness tracking
      await _brightnessTracker?.start();
      
      await _recordingManager.startRecording();
      setState(() {
        _isRecording = true;
        _elapsedTime = Duration.zero;
      });

      // Start timer
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) {
          setState(() {
            _elapsedTime = Duration(seconds: _elapsedTime.inSeconds + 1);
          });
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Recording started'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to start recording: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _stopRecording() async {
    try {
      _timer?.cancel();
      
      // Stop foreground service
      await ForegroundService.stop();
      _sensorService.setForegroundServiceActive(false);
      
      // Stop screen brightness tracking
      _brightnessTracker?.stop();

      final session = await _recordingManager.stopRecordingAndSave(
        meta: {'lightType': _selectedLightType},
      );

      setState(() {
        _isRecording = false;
      });

      // Navigate to processing screen
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ProcessingScreen(
              session: session,
              lightType: _selectedLightType,
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to stop recording: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$hours:$minutes:$seconds';
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _sensorSubscription?.cancel();
    _brightnessTracker?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isRecording ? 'Recording...' : 'Ready to Record'),
        backgroundColor: _isRecording ? Colors.red : Colors.deepPurple,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: _isRecording
                ? [Colors.red.shade700, Colors.red.shade400]
                : [Colors.deepPurple.shade700, Colors.deepPurple.shade400],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                // Timer display
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      Text(
                        _formatDuration(_elapsedTime),
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isRecording
                            ? 'Recording in progress'
                            : 'Tap below to start',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // Real-time sensor data
                if (_isRecording) ...[
                  _buildSensorCard(
                    'Ambient Light',
                    '${_currentLux.toStringAsFixed(1)} lux',
                    Icons.light_mode,
                  ),
                  const SizedBox(height: 16),
                  _buildSensorCard(
                    'Circadian Stimulus',
                    _currentCS.toStringAsFixed(3),
                    Icons.psychology,
                  ),
                ],

                if (!_isRecording) ...[
                  // Light type selector
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Select your lighting environment:',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _selectedLightType,
                          decoration: const InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'warm_led_2700k',
                              child: Text('Warm LED (2700K)'),
                            ),
                            DropdownMenuItem(
                              value: 'neutral_led_4000k',
                              child: Text('Neutral LED (4000K)'),
                            ),
                            DropdownMenuItem(
                              value: 'cool_led_5000k',
                              child: Text('Cool LED (5000K)'),
                            ),
                            DropdownMenuItem(
                              value: 'daylight_6500k',
                              child: Text('Daylight (6500K)'),
                            ),
                            DropdownMenuItem(
                              value: 'phone_screen',
                              child: Text('Phone Screen Dominant'),
                            ),
                            DropdownMenuItem(
                              value: 'incandescent',
                              child: Text('Incandescent Bulb'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _selectedLightType = value;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],

                const Spacer(),

                // Control button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isRecording ? _stopRecording : _startRecording,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor:
                          _isRecording ? Colors.red : Colors.deepPurple,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 8,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(_isRecording
                            ? Icons.stop
                            : Icons.fiber_manual_record),
                        const SizedBox(width: 12),
                        Text(
                          _isRecording ? 'Stop Recording' : 'Start Recording',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Safety notice
                if (_isRecording)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.white.withOpacity(0.9),
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Keep your phone in typical viewing position for accurate measurements.',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 12,
                            ),
                          ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.trending_up,
                              color: Colors.white.withOpacity(0.9),
                              size: 16,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Sensor smoothing can be adjusted in Settings.',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 11,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSensorCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
