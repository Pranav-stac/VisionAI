import 'dart:io';
import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class CameraService {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _isInitialized = false;
  int _initAttempts = 0;
  final int _maxInitAttempts = 3;
  Timer? _initTimer;
  Completer<void>? _initCompleter;
  
  // Getters
  CameraController? get controller => _controller;
  bool get isInitialized => _isInitialized;
  bool get hasCamera => _cameras.isNotEmpty;
  
  // Initialize cameras with retry mechanism
  Future<void> initialize() async {
    if (_initCompleter != null && !_initCompleter!.isCompleted) {
      // If initialization is already in progress, return the existing future
      return _initCompleter!.future;
    }
    
    _initCompleter = Completer<void>();
    _initAttempts = 0;
    
    try {
      // First check if we have camera permission
      final permissionStatus = await Permission.camera.status;
      if (!permissionStatus.isGranted) {
        print('Camera permission not granted');
        throw CameraException('permissionDenied', 'Camera permission not granted');
      }
      
      await _attemptInitialize();
    } catch (e) {
      if (!_initCompleter!.isCompleted) {
        _initCompleter!.completeError(e);
      }
    }
    
    return _initCompleter!.future;
  }
  
  Future<void> _attemptInitialize() async {
    _initAttempts++;
    print('Camera initialization attempt $_initAttempts of $_maxInitAttempts');
    
    try {
      if (_controller != null) {
        await _controller!.dispose();
        _controller = null;
      }

      print('Initializing camera...');
      
      // Add delay before trying to get cameras (helps on some devices)
      await Future.delayed(const Duration(milliseconds: 200));
      
      _cameras = await availableCameras();
      print('Found ${_cameras.length} cameras');
      
      if (_cameras.isEmpty) {
        print('No cameras available');
        throw CameraException('noCamera', 'No cameras available on this device');
      } else {
        // Create and initialize the controller
        await _initializeController(_cameras.first);
        print('Camera initialized successfully');
        
        // Complete the initialization completer
        if (!_initCompleter!.isCompleted) {
          _initCompleter!.complete();
        }
      }
    } on CameraException catch (e) {
      print('Camera error: ${e.code} - ${e.description}');
      
      // Check if we should retry
      if (_initAttempts < _maxInitAttempts) {
        print('Retrying camera initialization in 1 second...');
        _initTimer = Timer(const Duration(seconds: 1), () {
          _attemptInitialize();
        });
      } else {
        print('Max initialization attempts reached');
        if (!_initCompleter!.isCompleted) {
          _initCompleter!.completeError(e);
        }
        throw e;
      }
    } catch (e) {
      print('Unexpected camera error: $e');
      
      // Check if we should retry
      if (_initAttempts < _maxInitAttempts) {
        print('Retrying camera initialization in 1 second...');
        _initTimer = Timer(const Duration(seconds: 1), () {
          _attemptInitialize();
        });
      } else {
        print('Max initialization attempts reached');
        if (!_initCompleter!.isCompleted) {
          _initCompleter!.completeError(CameraException('cameraInit', 'Failed to initialize camera: $e'));
        }
        throw CameraException('cameraInit', 'Failed to initialize camera: $e');
      }
    }
  }
  
  // Initialize the camera controller with proper error handling
  Future<void> _initializeController(CameraDescription camera) async {
    if (_controller != null) {
      await _controller!.dispose();
    }
    
    print('Creating controller for camera: ${camera.name} (${camera.lensDirection})');
    _controller = CameraController(
      camera,
      ResolutionPreset.medium, // Lower resolution for better stability
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid ? ImageFormatGroup.yuv420 : ImageFormatGroup.jpeg,
    );
    
    try {
      print('Initializing camera controller...');
      
      // Add timeout for initialization
      await _controller!.initialize().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print('Camera initialization timed out');
          throw CameraException('initTimeout', 'Camera initialization timed out');
        },
      );
      
      print('Camera controller initialized');
      _isInitialized = true;
    } on CameraException catch (e) {
      print('Camera controller error: ${e.code} - ${e.description}');
      _isInitialized = false;
      
      // Use a more targeted approach to handle specific camera errors
      if (e.code == 'CameraAccessDenied') {
        // This is a permission issue
        throw CameraException('permissionDenied', 'Camera permission denied');
      } else if (e.code == 'CameraAccessRestricted') {
        // This is a restriction issue (parental controls, etc.)
        throw CameraException('accessRestricted', 'Camera access is restricted');
      }
      
      throw e;  // Rethrow to let caller handle it
    } catch (e) {
      print('Unexpected controller error: $e');
      _isInitialized = false;
      throw CameraException('controllerError', 'Failed to initialize controller: $e');
    }
  }
  
  // Switch between front and back camera
  Future<void> switchCamera() async {
    if (_cameras.length < 2) return;
    
    final lensDirection = _controller!.description.lensDirection;
    CameraDescription newCamera;
    
    if (lensDirection == CameraLensDirection.back) {
      newCamera = _cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras.first,
      );
    } else {
      newCamera = _cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras.first,
      );
    }
    
    await _initializeController(newCamera);
  }
  
  // Take a photo with robust error handling and recovery
  Future<File?> takePicture() async {
    if (!_isInitialized || _controller == null) {
      print('Camera not initialized, attempting to initialize before taking picture');
      try {
        await initialize();
        // If initialization failed, the error would be thrown
      } catch (e) {
        print('Failed to initialize camera: $e');
        throw CameraException('notInitialized', 'Camera is not initialized and could not be initialized: $e');
      }
    }
    
    // Double-check controller state
    if (_controller == null || !_controller!.value.isInitialized) {
      print('Camera controller not ready, attempting recovery...');
      try {
        // Force dispose and reinitialize
        if (_controller != null) {
          await _controller!.dispose();
          _controller = null;
        }
        
        _isInitialized = false;
        await initialize();
        
        if (!_isInitialized || _controller == null || !_controller!.value.isInitialized) {
          throw CameraException('notReady', 'Camera not ready after recovery attempt');
        }
      } catch (e) {
        print('Camera recovery failed: $e');
        throw CameraException('recoveryFailed', 'Failed to recover camera: $e');
      }
    }
    
    try {
      // Ensure flash is off to prevent inconsistent lighting
      await _controller!.setFlashMode(FlashMode.off);
      print('Taking picture...');
      
      // Add small delay to ensure camera is stable
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Take the picture
      final XFile image = await _controller!.takePicture();
      print('Picture taken: ${image.path}');
      
      // Get temporary directory
      final directory = await getTemporaryDirectory();
      final imagePath = '${directory.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      // Save image to temporary path
      final File imageFile = File(image.path);
      final savedImage = await imageFile.copy(imagePath);
      
      print('Picture saved successfully: $imagePath');
      return savedImage;
    } on CameraException catch (e) {
      print('CameraException during takePicture: ${e.code} - ${e.description}');
      
      // Detailed error handling based on error code
      if (e.code == 'cameraNotReady') {
        print('Camera not ready, attempting to recover...');
        
        // Wait a moment and try to re-initialize the camera
        await Future.delayed(const Duration(milliseconds: 500));
        try {
          await initialize();
          print('Camera reinitialized successfully after error');
          
          // Try taking picture again after recovery
          print('Retrying picture capture after recovery');
          return await takePicture();
        } catch (reinitError) {
          print('Failed to reinitialize camera: $reinitError');
          throw CameraException('recoveryFailed', 'Failed to recover camera: $reinitError');
        }
      } else if (e.code == 'captureError' || e.code == 'captureTimeout') {
        // Try once more after a delay
        print('Capture error or timeout, retrying once...');
        await Future.delayed(const Duration(milliseconds: 500));
        try {
          final XFile retry = await _controller!.takePicture();
          final directory = await getTemporaryDirectory();
          final imagePath = '${directory.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';
          final File imageFile = File(retry.path);
          return await imageFile.copy(imagePath);
        } catch (retryError) {
          print('Retry also failed: $retryError');
          throw CameraException('captureRetryFailed', 'Picture capture retry failed: $retryError');
        }
      }
      
      throw e;  // Rethrow other exceptions
    } catch (e) {
      print('Error during takePicture: $e');
      throw CameraException('captureError', 'Failed to capture image: $e');
    }
  }
  
  // Load an image from the gallery
  Future<File?> getImageFromGallery() async {
    try {
      // This would typically use image_picker, but we'll just simulate it here
      // In a real implementation, you would use ImagePicker().pickImage(source: ImageSource.gallery)
      
      // For now, we'll just return a placeholder image
      final ByteData data = await rootBundle.load('assets/images/placeholder.jpg');
      final directory = await getTemporaryDirectory();
      final path = '${directory.path}/placeholder_image.jpg';
      final File file = File(path);
      await file.writeAsBytes(data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));
      return file;
    } catch (e) {
      if (kDebugMode) {
        print('Error loading image: $e');
      }
      return null;
    }
  }
  
  // Dispose of the controller and cleanup resources
  Future<void> dispose() async {
    // Cancel any pending initialization timer
    _initTimer?.cancel();
    _initTimer = null;
    
    // Complete the initialization completer if it exists and isn't completed
    if (_initCompleter != null && !_initCompleter!.isCompleted) {
      _initCompleter!.completeError(CameraException('disposed', 'Camera service was disposed'));
    }
    
    if (_controller != null) {
      try {
        print('Disposing camera controller');
        await _controller!.dispose();
      } catch (e) {
        print('Error disposing camera controller: $e');
      } finally {
        _controller = null;
        _isInitialized = false;
      }
    }
  }
  
  // Force reset the camera service in case of severe issues
  Future<void> reset() async {
    print('Performing full camera service reset');
    await dispose();
    
    // Small delay to ensure complete cleanup
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Reset counters and state
    _initAttempts = 0;
    _isInitialized = false;
    _cameras = [];
    
    // Attempt to initialize fresh
    return initialize();
  }
} 