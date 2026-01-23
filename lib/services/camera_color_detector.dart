// lib/services/camera_color_detector.dart
//
// Step 5: Camera Service for Lighting Environment Detection
// Developer B Implementation - Independent (no dependencies on Developer A's code)

import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

/// Result of camera image capture (for use in Step 6 - Image Processor)
class CameraImageResult {
  final Uint8List imageBytes;
  final int width;
  final int height;
  final DateTime timestamp;
  
  const CameraImageResult({
    required this.imageBytes,
    required this.width,
    required this.height,
    required this.timestamp,
  });
}

/// Service for camera initialization and image capture
/// 
/// This service handles:
/// - Camera permission requests
/// - Camera initialization
/// - Image capture
/// - Error handling
/// 
/// Note: This is Step 5 - camera service only.
/// Color conversion will be integrated in Step 7.
class CameraColorDetector {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  String? _initializationError;
  
  /// Check if camera is initialized and ready
  bool get isReady => 
      _isInitialized && 
      _controller != null && 
      _controller!.value.isInitialized;
  
  /// Get initialization error message (if any)
  String? get initializationError => _initializationError;
  
  /// Get available cameras list
  List<CameraDescription>? get cameras => _cameras;
  
  /// Get current camera controller (for preview widget)
  CameraController? get controller => _controller;
  
  /// Initialize camera
  /// 
  /// Steps:
  /// 1. Check camera permission
  /// 2. Get available cameras
  /// 3. Select back camera (preferred) or first available
  /// 4. Initialize camera controller
  /// 
  /// Returns: true if successful, false otherwise
  Future<bool> initialize() async {
    try {
      // Step 1: Check camera permission
      final permissionStatus = await Permission.camera.status;
      if (!permissionStatus.isGranted) {
        if (kDebugMode) {
          debugPrint('CameraColorDetector: Camera permission not granted, requesting...');
        }
        
        final result = await Permission.camera.request();
        if (!result.isGranted) {
          _initializationError = 'Camera permission denied';
          if (kDebugMode) {
            debugPrint('CameraColorDetector: Camera permission denied by user');
          }
          return false;
        }
      }
      
      if (kDebugMode) {
        debugPrint('CameraColorDetector: Camera permission granted');
      }
      
      // Step 2: Get available cameras
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        _initializationError = 'No cameras available on this device';
        if (kDebugMode) {
          debugPrint('CameraColorDetector: No cameras available');
        }
        return false;
      }
      
      if (kDebugMode) {
        debugPrint('CameraColorDetector: Found ${_cameras!.length} camera(s)');
      }
      
      // Step 3: Select camera (prefer back camera)
      CameraDescription selectedCamera;
      try {
        selectedCamera = _cameras!.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.back,
        );
        if (kDebugMode) {
          debugPrint('CameraColorDetector: Using back camera');
        }
      } catch (e) {
        // No back camera, use first available
        selectedCamera = _cameras!.first;
        if (kDebugMode) {
          debugPrint('CameraColorDetector: No back camera found, using first available: ${selectedCamera.name}');
        }
      }
      
      // Step 4: Initialize camera controller
      // Use medium resolution for balance between quality and performance
      _controller = CameraController(
        selectedCamera,
        ResolutionPreset.medium,
        enableAudio: false, // No audio needed
      );
      
      await _controller!.initialize();
      
      _isInitialized = true;
      _initializationError = null;
      
      if (kDebugMode) {
        debugPrint('CameraColorDetector: Camera initialized successfully');
        debugPrint('CameraColorDetector: Resolution: ${_controller!.value.previewSize}');
      }
      
      return true;
    } catch (e, stackTrace) {
      _isInitialized = false;
      _initializationError = 'Failed to initialize camera: $e';
      
      if (kDebugMode) {
        debugPrint('CameraColorDetector: Error initializing camera: $e');
        debugPrint('CameraColorDetector: Stack trace: $stackTrace');
      }
      
      // Clean up on error
      await dispose();
      
      return false;
    }
  }
  
  /// Capture an image from the camera
  /// 
  /// Returns: CameraImageResult with image bytes and metadata
  /// Returns null if capture fails
  Future<CameraImageResult?> captureImage() async {
    if (!isReady) {
      if (kDebugMode) {
        debugPrint('CameraColorDetector: Camera not ready for capture');
      }
      return null;
    }
    
    try {
      if (kDebugMode) {
        debugPrint('CameraColorDetector: Capturing image...');
      }
      
      // Capture image
      final image = await _controller!.takePicture();
      
      // Read image bytes
      final imageBytes = await image.readAsBytes();
      
      // Get image dimensions from controller
      final previewSize = _controller!.value.previewSize;
      final width = previewSize?.width.toInt() ?? 0;
      final height = previewSize?.height.toInt() ?? 0;
      
      if (kDebugMode) {
        debugPrint('CameraColorDetector: Image captured successfully');
        debugPrint('CameraColorDetector: Image size: ${imageBytes.length} bytes');
        debugPrint('CameraColorDetector: Image dimensions: ${width}x$height');
      }
      
      return CameraImageResult(
        imageBytes: imageBytes,
        width: width,
        height: height,
        timestamp: DateTime.now(),
      );
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('CameraColorDetector: Error capturing image: $e');
        debugPrint('CameraColorDetector: Stack trace: $stackTrace');
      }
      return null;
    }
  }
  
  /// Get camera preview widget (for UI integration in Step 8)
  /// 
  /// Returns null if camera is not ready
  Widget? getPreviewWidget() {
    if (!isReady) {
      return null;
    }
    return CameraPreview(_controller!);
  }
  
  /// Check camera permission status
  /// 
  /// Returns: true if permission is granted, false otherwise
  Future<bool> checkPermission() async {
    final status = await Permission.camera.status;
    return status.isGranted;
  }
  
  /// Request camera permission
  /// 
  /// Returns: true if permission granted, false otherwise
  Future<bool> requestPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }
  
  /// Dispose camera resources
  /// 
  /// Call this when done with the camera to free resources
  Future<void> dispose() async {
    if (kDebugMode) {
      debugPrint('CameraColorDetector: Disposing camera resources...');
    }
    
    try {
      await _controller?.dispose();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('CameraColorDetector: Error disposing controller: $e');
      }
    } finally {
      _controller = null;
      _isInitialized = false;
      _initializationError = null;
    }
    
    if (kDebugMode) {
      debugPrint('CameraColorDetector: Camera resources disposed');
    }
  }
  
  /// Get camera state information (for debugging)
  Map<String, dynamic> getStateInfo() {
    return {
      'isInitialized': _isInitialized,
      'isReady': isReady,
      'hasController': _controller != null,
      'controllerInitialized': _controller?.value.isInitialized ?? false,
      'availableCameras': _cameras?.length ?? 0,
      'error': _initializationError,
      'previewSize': _controller?.value.previewSize?.toString(),
    };
  }
}
