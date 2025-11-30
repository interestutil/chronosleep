// lib/services/storage_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/session_data.dart';

class StorageService {
  Future<Directory> get _appDocDir async =>
      await getApplicationDocumentsDirectory();
  Future<File> _fileForSession(String id) async {
    final dir = await _appDocDir;
    return File('${dir.path}/session_$id.json');
  }

  Future<void> saveSession(SessionData session) async {
    final file = await _fileForSession(session.id);
    final jsonStr = jsonEncode(session.toJson());
    await file.writeAsString(jsonStr);
  }

  Future<SessionData?> loadSession(String id) async {
    try {
      final file = await _fileForSession(id);
      if (!await file.exists()) return null;
      final jsonStr = await file.readAsString();
      final Map<String, dynamic> map = jsonDecode(jsonStr);
      return SessionData.fromJson(map);
    } catch (e) {
      return null;
    }
  }

  Future<List<String>> listSessionIds() async {
    final dir = await _appDocDir;
    final files = dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.contains('session_'))
        .toList();
    return files.map((f) => f.path.split('/').last).toList();
  }
}
