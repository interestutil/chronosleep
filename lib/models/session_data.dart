// lib/models/session_data.dart
import 'light_sample.dart';

class SessionData {
  final String id; // uuid
  final DateTime startedAt;
  final DateTime stoppedAt;
  final List<LightSample> samples;
  final Map<String, dynamic>? meta;

  SessionData({
    required this.id,
    required this.startedAt,
    required this.stoppedAt,
    required this.samples,
    this.meta,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'startedAt': startedAt.toIso8601String(),
    'stoppedAt': stoppedAt.toIso8601String(),
    'samples': samples.map((s) => s.toJson()).toList(),
    'meta': meta,
  };

  static SessionData fromJson(Map<String, dynamic> j) => SessionData(
    id: j['id'] as String,
    startedAt: DateTime.parse(j['startedAt'] as String),
    stoppedAt: DateTime.parse(j['stoppedAt'] as String),
    samples: (j['samples'] as List)
        .map((e) => LightSample.fromJson(e as Map<String, dynamic>))
        .toList(),
    meta: j['meta'] as Map<String, dynamic>?,
  );
}
