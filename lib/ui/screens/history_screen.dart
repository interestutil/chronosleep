// lib/ui/screens/history_screen.dart
//
// Simple sessions history: lists saved sessions and lets user re-process them.

import 'dart:io';
import 'package:flutter/material.dart';
import '../../services/storage_service.dart';
import '../../services/processing_pipeline.dart';
import '../../services/multi_day_planner.dart';
import '../../models/results_model.dart';
import 'processing_screen.dart';
import 'multi_day_plan_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final StorageService _storage = StorageService();
  final ProcessingPipeline _pipeline = ProcessingPipeline();
  final MultiDayPlanner _multiDayPlanner = MultiDayPlanner();
  late Future<List<_SessionEntry>> _entriesFuture;

  @override
  void initState() {
    super.initState();
    _entriesFuture = _loadEntries();
  }

  Future<List<_SessionEntry>> _loadEntries() async {
    final dir = await _storage.appDocDir;
    final files = dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.contains('session_'))
        .toList()
      ..sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));

    final entries = <_SessionEntry>[];
    for (final f in files) {
      final name = f.path.split('/').last;
      entries.add(_SessionEntry(
        id: name.replaceAll('session_', '').replaceAll('.json', ''),
        fileName: name,
        modified: f.lastModifiedSync(),
      ));
    }
    return entries;
  }

  Future<void> _openSession(_SessionEntry entry) async {
    final session = await _storage.loadSession(entry.id);
    if (session == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load session ${entry.id}'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!mounted) return;
    Navigator.pushNamed(
      context,
      '/processing',
      arguments: {
        'session': session,
        'lightType': (session.meta?['lightType'] as String?) ?? 'neutral_led_4000k',
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Past Sessions'),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_graph),
            tooltip: 'Multi-day Plan',
            onPressed: () => _openMultiDayPlan(),
          ),
        ],
      ),
      body: FutureBuilder<List<_SessionEntry>>(
        future: _entriesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Failed to load sessions: ${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            );
          }
          final entries = snapshot.data ?? [];
          if (entries.isEmpty) {
            return const Center(
              child: Text('No saved sessions yet.'),
            );
          }
          return ListView.builder(
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final e = entries[index];
              return ListTile(
                title: Text('Session ${e.id.substring(0, 8)}'),
                subtitle: Text(
                  'Saved: ${e.modified}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _openSession(e),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _openMultiDayPlan() async {
    try {
      final entries = await _entriesFuture;
      if (!mounted) return;
      if (entries.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No sessions available for planning')),
        );
        return;
      }

      // Load and process up to the most recent 10 sessions
      final toUse = entries.take(10).toList();
      final results = <ResultsModel>[];
      for (final e in toUse) {
        final session = await _storage.loadSession(e.id);
        if (session == null) continue;
        final lightType =
            (session.meta?['lightType'] as String?) ?? 'neutral_led_4000k';
        final r =
            await _pipeline.process(session: session, lightType: lightType);
        results.add(r);
      }

      if (!mounted) return;
      if (results.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to process sessions for planning'),
          ),
        );
        return;
      }

      // Sort chronologically
      results.sort((a, b) => a.startTime.compareTo(b.startTime));
      final plan = _multiDayPlanner.planFromHistory(results);

      Navigator.pushNamed(
        context,
        '/multi_day_plan',
        arguments: {'plan': plan},
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to build multi-day plan: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class _SessionEntry {
  final String id;
  final String fileName;
  final DateTime modified;

  _SessionEntry({
    required this.id,
    required this.fileName,
    required this.modified,
  });
}


