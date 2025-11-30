// lib/services/recording_manager.dart
import 'dart:async';
import 'package:uuid/uuid.dart';
import '../models/light_sample.dart';
import '../models/session_data.dart';
import 'sensor_service.dart';
import 'storage_service.dart';

class RecordingManager {
  final SensorService sensorService;
  final StorageService storage;
  final Duration
  binDuration; // preferred sampling interval for buffer (not sensor)
  StreamSubscription<LightSample>? _sub;
  List<LightSample> _buffer = [];
  DateTime? _startedAt;
  DateTime? _stoppedAt;
  String? _sessionId;
  bool _isRecording = false;

  RecordingManager({
    required this.sensorService,
    required this.storage,
    this.binDuration = const Duration(seconds: 60),
  });

  bool get isRecording => _isRecording;

  Future<void> startRecording() async {
    if (_isRecording) return;
    _isRecording = true;
    _sessionId = Uuid().v4();
    _startedAt = DateTime.now().toUtc();
    _buffer = [];
    // subscribe directly to sensor samples
    _sub = sensorService.sampleStream.listen((LightSample sample) {
      // Optionally throttle/sampling logic:
      _buffer.add(sample);
    });
    // ensure sensors are started
    await sensorService.start();
  }

  Future<SessionData> stopRecordingAndSave({Map<String, dynamic>? meta}) async {
    if (!_isRecording) {
      throw StateError('Not recording');
    }
    _stoppedAt = DateTime.now().toUtc();
    _isRecording = false;
    await _sub?.cancel();
    await sensorService.stop();

    final session = SessionData(
      id: _sessionId!,
      startedAt: _startedAt!,
      stoppedAt: _stoppedAt!,
      samples: List.unmodifiable(_buffer),
      meta: meta,
    );

    await storage.saveSession(session);
    return session;
  }
}
