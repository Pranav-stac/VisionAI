import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

enum ConnectionQuality {
  offline,
  poor,
  moderate,
  good,
  excellent
}

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription? _subscription;
  
  // Current connection type
  ConnectivityResult _connectionType = ConnectivityResult.none;
  
  // Estimated connection quality
  ConnectionQuality _connectionQuality = ConnectionQuality.moderate;
  
  // Network speed test results
  int _lastDownloadSpeed = 0; // in kbps
  DateTime? _lastSpeedTest;
  
  // Getters
  ConnectivityResult get connectionType => _connectionType;
  ConnectionQuality get quality => _connectionQuality;
  int get downloadSpeed => _lastDownloadSpeed;
  
  // Stream controllers
  final _connectionStatusController = StreamController<ConnectivityResult>.broadcast();
  final _connectionQualityController = StreamController<ConnectionQuality>.broadcast();
  
  // Streams
  Stream<ConnectivityResult> get connectionStream => _connectionStatusController.stream;
  Stream<ConnectionQuality> get qualityStream => _connectionQualityController.stream;
  
  // Initialize connectivity monitoring
  Future<void> initialize() async {
    // Get initial connection status
    try {
      _connectionType = await _connectivity.checkConnectivity();
      _estimateConnectionQuality();
      
      // Listen for connectivity changes
      _subscription = _connectivity.onConnectivityChanged.listen((ConnectivityResult result) {
        _connectionType = result;
        _connectionStatusController.add(result);
        
        // Re-estimate connection quality when connection type changes
        _estimateConnectionQuality();
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing connectivity service: $e');
      }
    }
  }
  
  // Estimate connection quality based on connection type
  void _estimateConnectionQuality() {
    switch (_connectionType) {
      case ConnectivityResult.none:
        _connectionQuality = ConnectionQuality.offline;
        break;
      case ConnectivityResult.bluetooth:
      case ConnectivityResult.wifi:
        _connectionQuality = ConnectionQuality.good;
        break;
      case ConnectivityResult.ethernet:
        _connectionQuality = ConnectionQuality.excellent;
        break;
      case ConnectivityResult.mobile:
        _connectionQuality = ConnectionQuality.moderate;
        break;
      default:
        _connectionQuality = ConnectionQuality.moderate;
    }
    
    _connectionQualityController.add(_connectionQuality);
  }
  
  // Get recommended processing interval based on connection quality
  Duration getRecommendedProcessingInterval() {
    switch (_connectionQuality) {
      case ConnectionQuality.offline:
        return const Duration(seconds: 10); // Very slow when offline
      case ConnectionQuality.poor:
        return const Duration(seconds: 5); // Slow for poor connections
      case ConnectionQuality.moderate:
        return const Duration(seconds: 3); // Moderate speed
      case ConnectionQuality.good:
        return const Duration(seconds: 2); // Good speed
      case ConnectionQuality.excellent:
        return const Duration(milliseconds: 1500); // Excellent speed
    }
  }
  
  // Get recommended image quality based on connection speed
  int getRecommendedImageQuality() {
    switch (_connectionQuality) {
      case ConnectionQuality.offline:
        return 40; // Very low quality when offline
      case ConnectionQuality.poor:
        return 50; // Low quality for poor connections
      case ConnectionQuality.moderate:
        return 70; // Moderate quality
      case ConnectionQuality.good:
        return 80; // Good quality
      case ConnectionQuality.excellent:
        return 90; // Excellent quality
    }
  }
  
  // Get recommended image dimensions
  Map<String, int> getRecommendedImageDimensions() {
    switch (_connectionQuality) {
      case ConnectionQuality.offline:
        return {'width': 400, 'height': 300}; // Very small when offline
      case ConnectionQuality.poor:
        return {'width': 600, 'height': 450}; // Small for poor connections
      case ConnectionQuality.moderate:
        return {'width': 800, 'height': 600}; // Moderate size
      case ConnectionQuality.good:
        return {'width': 1024, 'height': 768}; // Good size
      case ConnectionQuality.excellent:
        return {'width': 1280, 'height': 960}; // Excellent size
    }
  }
  
  // Dispose resources
  void dispose() {
    _subscription?.cancel();
    _connectionStatusController.close();
    _connectionQualityController.close();
  }
} 