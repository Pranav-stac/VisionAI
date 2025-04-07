import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class CameraService {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _isInitialized = false;
  
  // Getters
  CameraController? get controller => _controller;
  bool get isInitialized => _isInitialized;
  bool get hasCamera => _cameras.isNotEmpty;
  
  // Initialize cameras
  Future<void> initialize() async {
    try {
      _cameras = await availableCameras();
      
      if (_cameras.isNotEmpty) {
        await _initializeController(_cameras.first);
      } else {
        if (kDebugMode) {
          print('No cameras available');
        }
      }
    } on CameraException catch (e) {
      if (kDebugMode) {
        print('Camera error: ${e.description}');
      }
    }
  }
  
  // Initialize the camera controller
  Future<void> _initializeController(CameraDescription camera) async {
    if (_controller != null) {
      await _controller!.dispose();
    }
    
    _controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );
    
    try {
      await _controller!.initialize();
      _isInitialized = true;
    } on CameraException catch (e) {
      if (kDebugMode) {
        print('Camera controller error: ${e.description}');
      }
      _isInitialized = false;
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
  
  // Take a photo
  Future<File?> takePicture() async {
    if (!_isInitialized || _controller == null) {
      return null;
    }
    
    try {
      // Ensure flash is off to prevent inconsistent lighting
      await _controller!.setFlashMode(FlashMode.off);
      
      // Take the picture
      final XFile image = await _controller!.takePicture();
      
      // Get temporary directory
      final directory = await getTemporaryDirectory();
      final imagePath = '${directory.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      // Save image to temporary path
      final File imageFile = File(image.path);
      final savedImage = await imageFile.copy(imagePath);
      
      return savedImage;
    } on CameraException catch (e) {
      if (kDebugMode) {
        print('Error taking photo: ${e.description}');
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error saving photo: $e');
      }
      return null;
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
  
  // Dispose of the controller
  Future<void> dispose() async {
    if (_controller != null) {
      await _controller!.dispose();
      _controller = null;
    }
    _isInitialized = false;
  }
} 