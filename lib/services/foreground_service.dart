// lib/services/foreground_service.dart
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

/// Manages the foreground service for keeping sensors active in background
class ForegroundService {
  static const MethodChannel _channel = MethodChannel('com.example.chronosleep/foreground_service');

  /// Start the foreground service to keep sensors running in background
  static Future<bool> start() async {
    try {
      if (kDebugMode) {
        debugPrint('ForegroundService: Attempting to start service...');
      }
      
      // Request notification permission for Android 13+
      if (await Permission.notification.isDenied) {
        if (kDebugMode) {
          debugPrint('ForegroundService: Requesting notification permission...');
        }
        final status = await Permission.notification.request();
        if (status.isDenied) {
          if (kDebugMode) {
            debugPrint('ForegroundService: Notification permission denied - service may not work');
          }
          // Continue anyway - some devices may still allow the service
        } else if (kDebugMode) {
          debugPrint('ForegroundService: Notification permission granted');
        }
      }
      
      final result = await _channel.invokeMethod<bool>('startForegroundService');
      if (kDebugMode) {
        debugPrint('ForegroundService: Service start result: $result');
      }
      if (result == null || result == false) {
        if (kDebugMode) {
          debugPrint('ForegroundService: WARNING - Service returned false or null');
        }
      }
      return result ?? false;
    } on PlatformException catch (e) {
      if (kDebugMode) {
        debugPrint('ForegroundService: PlatformException starting service: ${e.code} - ${e.message}');
        debugPrint('ForegroundService: Details: ${e.details}');
      }
      return false;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('ForegroundService: Error starting service: $e');
        debugPrint('ForegroundService: Stack trace: $stackTrace');
      }
      return false;
    }
  }

  /// Stop the foreground service
  static Future<bool> stop() async {
    try {
      final result = await _channel.invokeMethod<bool>('stopForegroundService');
      if (kDebugMode) {
        debugPrint('ForegroundService: Stopped - $result');
      }
      return result ?? false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('ForegroundService: Error stopping service: $e');
      }
      return false;
    }
  }
}

