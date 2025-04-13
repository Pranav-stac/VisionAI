import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';
import '../../models/scene_description.dart';
import '../../providers/scene_description_provider.dart';
import '../../services/camera_service.dart';
import '../../services/gemini_service.dart';
import '../../services/image_utils.dart';
import '../../services/connectivity_service.dart';
import 'scene_question_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:permission_handler/permission_handler.dart';

class SceneDescriptionScreen extends StatefulWidget {
  const SceneDescriptionScreen({super.key});

  @override
  State<SceneDescriptionScreen> createState() => _SceneDescriptionScreenState();
}

class _SceneDescriptionScreenState extends State<SceneDescriptionScreen> with SingleTickerProviderStateMixin {
  bool _isScanning = false;
  String _currentDescription = '';
  List<SceneItem> _sceneHistory = [];
  late AnimationController _animationController;
  late Animation<double> _animation;
  Timer? _scanTimer;
  bool _isLiveMode = true;
  bool _adaptiveIntervalsEnabled = true;
  
  // Camera Service
  final CameraService _cameraService = CameraService();
  FlutterTts? _flutterTts;
  bool _isSpeaking = false;
  
  // Speech to text variables
  late stt.SpeechToText _speech;
  bool _isListeningForVoiceCommand = false;
  bool _speechAvailable = false;
  
  // Gemini API service for image analysis
  final GeminiService _geminiService = GeminiService();
  
  // Connectivity service for network quality
  final ConnectivityService _connectivityService = ConnectivityService();
  
  // Tracking time between scans
  DateTime _lastScanTime = DateTime.now();
  
  // Scanning interval that can be adjusted based on network quality
  Duration _currentScanInterval = const Duration(milliseconds: 3000);

  // Add a flag to track permission status
  bool _cameraPermissionGranted = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_animationController)
      ..addListener(() {
        setState(() {});
      });
    
    // Create speech instance
    _speech = stt.SpeechToText();
    
    // Initialize provider first, then services
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SceneDescriptionProvider>(context, listen: false).init();
      // Check camera permissions first, then initialize services
      _checkCameraPermission();
    });
    
    // Start animation for scanning effect
    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scanTimer?.cancel();
    _speech.stop();
    _geminiService.dispose();
    _connectivityService.dispose();
    super.dispose();
  }

  void _toggleScanning() {
    setState(() {
      _isScanning = !_isScanning;
    });

    if (_isScanning) {
      _startScanning();
    } else {
      _scanTimer?.cancel();
    }
  }

  void _startScanning() {
    // In a real app, you would use camera and AI to analyze the scene
    
    if (_isLiveMode) {
      // Generate first description immediately
      _generateDescription();
      
      // Start the scanning timer with adaptive interval
      _startScanningTimer();
    } else {
      // Single scan mode
      _generateDescription();
      setState(() {
        _isScanning = false;
      });
    }
  }

  void _startScanningTimer() {
    // Cancel existing timer if any
    _scanTimer?.cancel();
    
    // Use adaptive interval based on connection quality and API response time
    if (_adaptiveIntervalsEnabled) {
      _currentScanInterval = _geminiService.getRecommendedScanningInterval();
      
      if (kDebugMode) {
        print('Setting adaptive scan interval: ${_currentScanInterval.inMilliseconds}ms');
      }
    }
    
    _scanTimer = Timer.periodic(_currentScanInterval, (timer) {
      // Ensure minimum time between scans to prevent overwhelming the API and camera
      final timeSinceLastScan = DateTime.now().difference(_lastScanTime);
      
      // Increase minimum time between scans to 2.5 seconds (was causing issues at <2 seconds)
      final minimumScanInterval = const Duration(milliseconds: 2500);
      
      if (timeSinceLastScan < minimumScanInterval) {
        if (kDebugMode) {
          print('Skipping scan, too soon since last scan (${timeSinceLastScan.inMilliseconds}ms)');
        }
        return;
      }
      
      // Only generate a new description if not currently speaking or loading
      if (!_isSpeaking && !Provider.of<SceneDescriptionProvider>(context, listen: false).isLoading) {
        _generateDescription();
      }
    });
  }

  void _generateDescription() async {
    // Record start time for tracking
    _lastScanTime = DateTime.now();
    
    // Stop any ongoing speech first
    await _stopSpeech();
    
    setState(() {
      // Show loading state
      Provider.of<SceneDescriptionProvider>(context, listen: false).setLoading(true);
    });

    try {
      // Add a small delay before taking a picture to ensure camera is ready
      await Future.delayed(Duration(milliseconds: 300));
      
      // Ensure camera is initialized
      if (!_cameraService.isInitialized) {
        print('Camera not initialized, attempting to initialize...');
        try {
          await _cameraService.initialize();
          // Wait for camera to be ready
          await Future.delayed(Duration(milliseconds: 500));
          
          if (!_cameraService.isInitialized) {
            // If still not initialized, show error but don't throw yet
            print('Camera initialization still not complete, will try to capture anyway');
          }
        } catch (e) {
          print('Failed to initialize camera: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Camera error: $e. Please try again.'),
              duration: Duration(seconds: 5),
              action: SnackBarAction(
                label: 'Retry',
                onPressed: () {
                  _cameraService.reset().then((_) => _generateDescription());
                },
              ),
            ),
          );
          // Continue rather than throwing - maybe we can still get a picture
        }
      }
      
      // Take a picture
      File? imageFile;
      try {
        imageFile = await _cameraService.takePicture();
      } catch (e) {
        print('Failed to take picture: $e');
        
        // Try to reset the camera and take picture again
        try {
          print('Attempting camera recovery and retrying picture...');
          await _cameraService.reset();
          await Future.delayed(Duration(milliseconds: 500));
          imageFile = await _cameraService.takePicture();
        } catch (retryError) {
          print('Retry also failed: $retryError');
          throw Exception('Failed to capture image after multiple attempts. Please try again.');
        }
      }
      
      if (imageFile == null) {
        throw Exception('Failed to capture image - camera may not be available');
      }

      if (kDebugMode) {
      print('Image captured successfully: ${imageFile.path}');
      }
      
      // Process the image with Gemini
      final result = await _geminiService.analyzeImage(imageFile.path);
      
      if (kDebugMode) {
        print('Gemini response: $result');
      }
      
      // Remove any "Image analysis:" prefix from the description
      String processedDescription = result;
      if (processedDescription.startsWith("Image analysis:")) {
        processedDescription = processedDescription.substring("Image analysis:".length).trim();
      }
      if (processedDescription.startsWith("Analysis:")) {
        processedDescription = processedDescription.substring("Analysis:".length).trim();
      }
      if (processedDescription.startsWith("In this image,")) {
        processedDescription = processedDescription.substring("In this image,".length).trim();
      }
      if (processedDescription.startsWith("The image shows")) {
        processedDescription = processedDescription.substring("The image shows".length).trim();
      }
      
      // Update the scene description
        setState(() {
        _currentDescription = processedDescription;
        });

        // Speak the description automatically
      _speakDescription(processedDescription);
      
      // Add to history
      _addToHistory(processedDescription, imageFile.path);
      
      // Update the provider
      final provider = Provider.of<SceneDescriptionProvider>(context, listen: false);
      provider.addScene(processedDescription, imageFile.path);
      provider.setLoading(false);
      
    } catch (e) {
      if (kDebugMode) {
        print('Error in _generateDescription: $e');
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Retry',
            onPressed: _generateDescription,
          ),
        ),
      );
      
      // Make sure we reset loading state
        Provider.of<SceneDescriptionProvider>(context, listen: false).setLoading(false);
    } finally {
      // Update last scan time to prevent too frequent API calls
      _lastScanTime = DateTime.now();
    }
  }

  void _toggleMode() {
    setState(() {
      _isLiveMode = !_isLiveMode;
      if (_isScanning && !_isLiveMode) {
        _isScanning = false;
        _scanTimer?.cancel();
      }
    });
  }

  void _clearHistory() {
    setState(() {
      _sceneHistory.clear();
      _currentDescription = '';
    });
  }

  Future<void> _initCamera() async {
    if (!_cameraPermissionGranted) {
      await _checkCameraPermission();
      return;
    }
    
    try {
    await _cameraService.initialize();
    setState(() {});
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing camera: $e');
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error initializing camera: ${e.toString()}'),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Retry',
            onPressed: _initCamera,
          ),
        ),
      );
    }
  }
  
  Future<void> _initTts() async {
    try {
      print('Initializing TTS engine...');
    _flutterTts = FlutterTts();
    
      // Set up completion handler
      _flutterTts!.setCompletionHandler(() {
        print('TTS completion handler called');
        if (mounted) {
          setState(() {
            _isSpeaking = false;
          });
        }
      });
      
      // Set up error handler
      _flutterTts!.setErrorHandler((error) {
        print('TTS error: $error');
        if (mounted) {
          setState(() {
            _isSpeaking = false;
          });
        }
      });
      
      // Load settings from shared preferences
      final prefs = await SharedPreferences.getInstance();
      final language = prefs.getString('tts_language') ?? 'en-US';
      final speechRate = prefs.getDouble('tts_speech_rate') ?? 0.5;
      final volume = prefs.getDouble('tts_volume') ?? 1.0;
      final pitch = prefs.getDouble('tts_pitch') ?? 1.0;
      
      // Apply settings
      await _flutterTts!.setLanguage(language);
      await _flutterTts!.setSpeechRate(speechRate);
      await _flutterTts!.setVolume(volume);
      await _flutterTts!.setPitch(pitch);
      
      // Additional Android-specific settings
      if (Platform.isAndroid) {
        await _flutterTts!.setQueueMode(1); // Use flush mode
        await _flutterTts!.awaitSpeakCompletion(true);
      }
      
      print('TTS engine initialized successfully with language: $language');
      print('TTS settings: rate=$speechRate, volume=$volume, pitch=$pitch');
      
      // Test TTS is working
      if (kDebugMode) {
        final result = await _flutterTts!.speak('Scene description ready');
        print('TTS initialization test result: $result');
      }
    } catch (e) {
      print('Error initializing TTS: $e');
      _flutterTts = null;
      
      // Report error but don't block app usage
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Text-to-speech initialization failed: ${e.toString()}'),
            duration: Duration(seconds: 5),
          ),
        );
      }
    }
  }

  // Add dedicated method to ensure TTS is working
  Future<bool> _ensureTtsIsReady() async {
    if (_flutterTts == null) {
      print('TTS not initialized - initializing now');
      await _initTts();
    }
    
    if (_flutterTts == null) {
      print('Failed to initialize TTS');
      return false;
    }
    
    // Always stop any current speech first
    if (_isSpeaking) {
      print('Stopping current speech before new utterance');
      try {
        await _flutterTts!.stop();
      setState(() {
        _isSpeaking = false;
        });
        // Small delay to ensure speech engine is ready
        await Future.delayed(Duration(milliseconds: 300));
      } catch (e) {
        print('Error stopping current speech: $e');
        // Continue anyway
      }
    }
    
    return true;
  }

  // Initialize speech recognition
  void _initSpeech() async {
    _speechAvailable = await _speech.initialize(
      onStatus: (status) => print('Speech recognition status: $status'),
      onError: (error) => print('Speech recognition error: $error'),
    );
    setState(() {});
  }
  
  // Start listening for voice commands
  void _startListeningForVoiceCommand() async {
    if (!_speechAvailable) {
      print('Speech recognition not available');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Speech recognition not available on this device'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    
    setState(() {
      _isListeningForVoiceCommand = true;
    });
    
    // Get the current language from preferences
    final prefs = await SharedPreferences.getInstance();
    String languageCode = prefs.getString('tts_language') ?? 'en-US';
    String speechLocale = 'en_US';
    
    // Map TTS language code to STT locale
    if (languageCode == 'hi-IN') {
      speechLocale = 'hi_IN';
    } else if (languageCode == 'es-ES') {
      speechLocale = 'es_ES';
    } else if (languageCode == 'fr-FR') {
      speechLocale = 'fr_FR';
    } else if (languageCode == 'de-DE') {
      speechLocale = 'de_DE';
    }
    
    await _speech.listen(
      onResult: _onVoiceCommandResult,
      listenFor: const Duration(seconds: 5),
      pauseFor: const Duration(seconds: 3),
      partialResults: true,
      localeId: speechLocale,
    );
  }
  
  // Stop listening for voice commands
  void _stopListeningForVoiceCommand() async {
    await _speech.stop();
    setState(() {
      _isListeningForVoiceCommand = false;
    });
  }
  
  // Handle voice command results
  void _onVoiceCommandResult(SpeechRecognitionResult result) {
    print('Voice command recognized: ${result.recognizedWords}');
    if (result.finalResult) {
      setState(() {
        _isListeningForVoiceCommand = false;
      });
      
      // Process the voice command
      _processVoiceCommand(result.recognizedWords.toLowerCase());
    }
  }
  
  // Process voice command
  void _processVoiceCommand(String command) {
    // Handle different commands
    if (command.contains('describe') || command.contains('scan') || 
        command.contains('what do you see') || command.contains('tell me') ||
        command.contains('batao') || command.contains('dekho')) {
      
      // Generate description
      _generateDescription();
    } 
    // Handle text recognition commands in Hindi and English
    else if (command.contains('text') || command.contains('likha') || 
             command.contains('likha hua') || command.contains('kya likha') ||
             command.contains('read') || command.contains('padho')) {
      
      // Analyze text in the scene
      _analyzeSpecificInfo('text');
    }
    // Handle questions about specific objects
    else if (command.contains('laptop') || command.contains('phone') || 
             command.contains('screen') || command.contains('tv') ||
             command.contains('mobile') || command.contains('computer')) {
      
      // If it seems like a question about what's written on a device
      if (command.contains('kya likha') || command.contains('what') || 
          command.contains('written') || command.contains('show')) {
        _analyzeSpecificInfo('text');
      }
      // For general object identification
      else {
        _analyzeSpecificInfo('location');
      }
    }
    // Handle questions about people
    else if (command.contains('who') || command.contains('person') || 
             command.contains('people') || command.contains('kaun') ||
             command.contains('log') || command.contains('aadmi')) {
      
      _analyzeSpecificInfo('people');
    }
    // Handle hazard questions
    else if (command.contains('hazard') || command.contains('danger') || 
             command.contains('safe') || command.contains('khatra')) {
      
      _analyzeSpecificInfo('hazards');
    }
    // Handle location/setting questions
    else if (command.contains('where') || command.contains('place') || 
             command.contains('location') || command.contains('kahan') ||
             command.contains('jagah')) {
      
      _analyzeSpecificInfo('location');
    }
    else if (command.contains('stop') || command.contains('cancel') || 
             command.contains('ruko') || command.contains('band karo')) {
      
      // Stop scanning/speaking
      if (_isScanning) {
        _toggleScanning();
      }
      if (_isSpeaking) {
        _flutterTts?.stop();
        setState(() {
          _isSpeaking = false;
        });
      }
    }
    else if (command.contains('live') || command.contains('live mode') || 
             command.contains('start live') || command.contains('live scan')) {
      
      // Start live mode
      if (!_isLiveMode) {
        _toggleMode();
      }
      if (!_isScanning) {
        _toggleScanning();
      }
    }
    else if (command.contains('single') || command.contains('single scan') || 
             command.contains('once')) {
      
      // Switch to single scan mode
      if (_isLiveMode) {
        _toggleMode();
      }
      _generateDescription();
    }
    // If no specific command is recognized but it sounds like a question
    // (ends with a question word or has question structure)
    else if (command.contains('?') || command.contains('kya') || 
            command.contains('kaun') || command.contains('kahan') ||
            command.contains('kitna') || command.contains('kaise') ||
            command.contains('what') || command.contains('who') ||
            command.contains('where') || command.contains('when') ||
            command.contains('how') || command.contains('why')) {
      
      // If we have a current scene, navigate to question screen
      final provider = Provider.of<SceneDescriptionProvider>(context, listen: false);
      if (provider.currentScene != null) {
        _navigateToQuestionScreen(provider.currentScene!.id);
        
        // Show a message that they can ask the question in the question screen
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please ask your question in the question screen'),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 3),
          ),
        );
      } else {
        // If no scene yet, generate one first
        _generateDescription();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final size = MediaQuery.of(context).size;
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scene Description'),
        actions: [
          IconButton(
            icon: Icon(_isListeningForVoiceCommand ? Icons.mic_off : Icons.mic),
            tooltip: 'Voice commands',
            color: _isListeningForVoiceCommand ? Colors.red : null,
            onPressed: _isListeningForVoiceCommand 
                ? _stopListeningForVoiceCommand 
                : _startListeningForVoiceCommand,
          ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              _showHistoryBottomSheet(context);
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              // Navigate to scene description settings
              _showSettingsDialog();
            },
          ),
          // Add connection quality indicator
          _buildConnectionQualityIndicator(),
          
          // Add menu for settings
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'adaptive') {
                _toggleAdaptiveIntervals();
              } else if (value == 'clear') {
                _clearHistory();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'adaptive',
                child: Row(
                  children: [
                    Icon(
                      _adaptiveIntervalsEnabled 
                          ? Icons.check_box 
                          : Icons.check_box_outline_blank,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    const Text('Adaptive Scanning'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear',
                child: Text('Clear History'),
              ),
            ],
          ),
        ],
      ),
      body: Consumer<SceneDescriptionProvider>(
        builder: (context, provider, child) {
          final isLoading = provider.isLoading;
          
          return Column(
            children: [
              // Mode Selector
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey[900] : Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildModeButton(
                      icon: Icons.videocam,
                      label: 'Live Mode',
                      isSelected: _isLiveMode,
                      onTap: () {
                        if (!_isLiveMode) _toggleMode();
                      },
                    ),
                    const SizedBox(width: 16),
                    _buildModeButton(
                      icon: Icons.camera_alt,
                      label: 'Single Scan',
                      isSelected: !_isLiveMode,
                      onTap: () {
                        if (_isLiveMode) _toggleMode();
                      },
                    ),
                  ],
                ),
              ),

              // Camera Preview / Current Scene
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Camera preview - add permission check
                    if (_cameraService.isInitialized && _cameraService.controller != null && _cameraPermissionGranted)
                      GestureDetector(
                        onTap: () {
                          // Capture image when tapping anywhere on the camera preview
                          _generateDescription();
                        },
                        onLongPress: () {
                          // Start listening for voice query on long press
                          _startListeningForVoiceQuery();
                        },
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CameraPreview(_cameraService.controller!),
                            
                            // Add voice query indicator
                            if (_isListeningForVoiceCommand)
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.mic, color: Colors.white),
                                    SizedBox(width: 10),
                                    Text(
                                      'Listening...',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      )
                    // Show permission request UI when permission not granted
                    else if (!_cameraPermissionGranted)
                      Container(
                          width: double.infinity,
                          height: double.infinity,
                        color: Colors.black,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.camera_alt,
                                size: 80,
                                color: Colors.white.withOpacity(0.5),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Camera permission required',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.white.withOpacity(0.9),
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Please grant camera permission to use this feature',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white.withOpacity(0.7),
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton(
                                onPressed: _requestCameraPermission,
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                ),
                                child: const Text('Grant Permission'),
                              ),
                            ],
                          ),
                        ),
                      )
                    // Placeholder when camera not available but permission granted
                    else
                      Container(
                        width: double.infinity,
                        height: double.infinity,
                        color: Colors.black,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.camera_alt,
                                size: 80,
                                color: Colors.white.withOpacity(0.5),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Camera not available',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white.withOpacity(0.7),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Loading indicator
                    if (isLoading)
                      Container(
                        color: Colors.black.withOpacity(0.5),
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),

                    // Scanning animation
                    if (_isScanning && !isLoading)
                      Container(
                        width: double.infinity,
                        height: 2,
                        margin: EdgeInsets.only(top: size.height * 0.3 * _animation.value),
                        color: colorScheme.primary,
                      ),

                    // Add a bottom controls overlay for speech and capture
                      Positioned(
                      bottom: 16,
                      left: 16,
                      right: 16,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Speech controls
                          Container(
                          decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Stop speech button
                                IconButton(
                                  icon: const Icon(Icons.stop_circle, color: Colors.red),
                                  onPressed: _isSpeaking ? _stopSpeech : null,
                                  tooltip: 'Stop speech',
                                  iconSize: 32,
                                ),
                                
                                // Replay last description button
                                IconButton(
                                  icon: const Icon(Icons.replay, color: Colors.white),
                                  onPressed: _currentDescription.isNotEmpty ? 
                                    () => _speakDescription(_currentDescription) : null,
                                  tooltip: 'Replay description',
                                  iconSize: 32,
                                ),
                              ],
                            ),
                          ),
                          
                          // Speech status indicator
                          if (_isSpeaking)
                                  Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.volume_up,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Speaking...',
                                      style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),

                    // Current scene description panel
                    Positioned(
                      top: 16,
                      left: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Current Scene',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                ),
                                if (_currentDescription.isNotEmpty)
                                  IconButton(
                                    icon: const Icon(Icons.more_horiz, color: Colors.white),
                                    onPressed: () => _showFullDescriptionDialog(_currentDescription),
                                    tooltip: 'View full description',
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                              _currentDescription.isEmpty
                                  ? 'Tap anywhere on the camera view to describe the scene'
                                  : _currentDescription,
                                style: const TextStyle(
                                fontSize: 14,
                                  color: Colors.white,
                                height: 1.3,
                                ),
                              maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Controls
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey[900] : Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Feature buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildFeatureButton(
                          icon: Icons.location_on,
                          label: 'Location',
                          onTap: () => _analyzeSpecificInfo('location'),
                        ),
                        _buildFeatureButton(
                          icon: Icons.people,
                          label: 'People',
                          onTap: () => _analyzeSpecificInfo('people'),
                        ),
                        _buildFeatureButton(
                          icon: Icons.text_fields,
                          label: 'Text',
                          onTap: () => _analyzeSpecificInfo('text'),
                        ),
                        _buildFeatureButton(
                          icon: Icons.warning,
                          label: 'Hazards',
                          onTap: () => _analyzeSpecificInfo('hazards'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Main action button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: isLoading ? null : () {
                            // Instead of toggling scanning, just capture a single image
                            if (!isLoading && !_isScanning) {
                              _generateDescription();
                            } else if (_isScanning) {
                              _toggleScanning(); // Stop scanning if already active
                            }
                          },
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: isLoading
                                  ? Colors.grey
                                  : _isScanning
                                      ? Colors.red
                                      : colorScheme.primary,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: isLoading
                                      ? Colors.grey.withOpacity(0.3)
                                      : _isScanning
                                          ? Colors.red.withOpacity(0.3)
                                          : colorScheme.primary.withOpacity(0.3),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                  spreadRadius: 3,
                                ),
                              ],
                            ),
                            child: isLoading
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                : Icon(
                                    _isLiveMode
                                        ? (_isScanning ? Icons.stop : Icons.videocam)
                                        : Icons.camera_alt,
                                    color: Colors.white,
                                    size: 36,
                                  ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Status text
                    Text(
                      isLoading
                          ? 'Processing image...'
                          : _isScanning
                              ? _isLiveMode
                                  ? 'Live description active... Tap to stop'
                                  : 'Scanning scene...'
                              : _isLiveMode
                                  ? 'Tap anywhere on camera view to start scan'
                                  : 'Tap anywhere on camera view to scan the scene',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildModeButton({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primary
              : theme.brightness == Brightness.light
                  ? Colors.grey[100]
                  : Colors.grey[800],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected
                  ? colorScheme.onPrimary
                  : theme.brightness == Brightness.light
                      ? Colors.black
                      : Colors.white,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? colorScheme.onPrimary
                    : theme.brightness == Brightness.light
                        ? Colors.black
                        : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: theme.brightness == Brightness.light
                    ? Colors.grey[100]
                    : Colors.grey[800],
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 24,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showHistoryBottomSheet(BuildContext context) {
    final provider = Provider.of<SceneDescriptionProvider>(context, listen: false);
    final sceneHistory = provider.sceneHistory;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  // Handle
                  Container(
                    width: 40,
                    height: 5,
                    margin: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2.5),
                    ),
                  ),
                  // Title
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Scene History',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                        ),
                      ],
                    ),
                  ),
                  const Divider(),
                  // History list
                  Expanded(
                    child: sceneHistory.isEmpty
                        ? Center(
                            child: Text(
                              'No scene history yet',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          )
                        : ListView.builder(
                            controller: scrollController,
                            padding: const EdgeInsets.all(16),
                            itemCount: sceneHistory.length,
                            itemBuilder: (context, index) {
                              final scene = sceneHistory[index];
                              
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).brightness == Brightness.light
                                        ? Colors.white
                                        : Colors.grey[800],
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 5,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Scene image
                                      if (scene.imagePath != null)
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(12),
                                          child: Image.file(
                                            File(scene.imagePath!),
                                            height: 120,
                                            width: double.infinity,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      const SizedBox(height: 12),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            _formatDateTime(scene.timestamp),
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                          Row(
                                            children: [
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.volume_up,
                                                  color: Colors.blue,
                                                ),
                                                onPressed: () => _speakDescription(scene.description),
                                              ),
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.question_answer,
                                                  color: Colors.green,
                                                ),
                                                onPressed: () => _navigateToQuestionScreen(scene.id),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        scene.description,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          height: 1.4,
                                        ),
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                          _showFullDescriptionDialog(scene.description);
                                        },
                                        child: const Text('Read More'),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  if (sceneHistory.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _showClearHistoryDialog();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Clear History'),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showFullDescriptionDialog(String description) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Scene Description'),
            IconButton(
              icon: Icon(_isSpeaking ? Icons.stop : Icons.volume_up),
              onPressed: _isSpeaking 
                ? _stopSpeech 
                : () => _speakDescription(description),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Text(
            description,
            style: const TextStyle(fontSize: 16, height: 1.5),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
  
  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Scene Description Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.api),
              title: const Text('OpenAI API Key'),
              subtitle: const Text('Set your OpenAI API key for image analysis'),
              onTap: () {
                Navigator.pop(context);
                _showApiKeyDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.mic),
              title: const Text('Speech Settings'),
              subtitle: const Text('Configure text-to-speech options'),
              onTap: () {
                Navigator.pop(context);
                _showTtsSettingsDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera Settings'),
              subtitle: const Text('Configure camera and resolution'),
              onTap: () {
                Navigator.pop(context);
                // Show camera settings
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
  
  void _showApiKeyDialog() {
    final TextEditingController controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set OpenAI API Key'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter your OpenAI API key to enable image analysis. Your key is stored securely on your device.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'API Key',
                border: OutlineInputBorder(),
                hintText: 'sk-...',
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                final provider = Provider.of<SceneDescriptionProvider>(context, listen: false);
                final geminiService = GeminiService();
                await geminiService.setApiKey(controller.text);
                if (mounted) Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('API key saved'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
  
  void _showClearHistoryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear History'),
        content: const Text('Are you sure you want to clear all scene history? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await Provider.of<SceneDescriptionProvider>(context, listen: false).clearHistory();
              if (mounted) {
                Navigator.pop(context);
                setState(() {
                  _currentDescription = '';
                });
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
  
  void _navigateToQuestionScreen(String sceneId) {
    Navigator.push(
      context, 
      MaterialPageRoute(
        builder: (context) => SceneQuestionScreen(sceneId: sceneId),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    
    return '$day/$month ${hour}:$minute';
  }

  void _analyzeSpecificInfo(String infoType) async {
    if (!_cameraService.isInitialized) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Camera is not available'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    
    final provider = Provider.of<SceneDescriptionProvider>(context, listen: false);
    
    // If we don't have a current scene, take a picture first
    if (provider.currentScene == null) {
      try {
        setState(() {
          provider.setLoading(true);
        });
        
        // Take a picture
        final imageFile = await _cameraService.takePicture();
        if (imageFile == null) {
          throw Exception('Failed to capture image');
        }
        
        // Set the image file in the provider
        provider.setImageFile(imageFile);
        
        // Generate a basic description first
        await provider.generateDescription();
      } catch (e) {
        print('Error capturing image: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        setState(() {
          provider.setLoading(false);
        });
        return;
      }
    }
    
    // Now analyze for specific info
    try {
      await provider.analyzeSceneForInfo(infoType);
      
      // Get the analysis result
      final result = provider.currentScene?.analysisResults?[infoType];
      
      if (result != null) {
        // Update the current description
        setState(() {
          _currentDescription = result;
        });
        
        // IMPORTANT: Always speak the result from button presses
        _speakDescription(result);
      }
    } catch (e) {
      print('Error analyzing for $infoType: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error analyzing for $infoType: ${e.toString()}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() {
        provider.setLoading(false);
      });
    }
  }

  void _speakDescription(String description) async {
    if (description.isEmpty) {
      print('Empty description - nothing to speak');
      return;
    }

    // Always stop any existing speech first
    await _stopSpeech();
    
    // Make sure TTS is ready
    bool ttsReady = await _ensureTtsIsReady();
    if (!ttsReady) {
      print('TTS not ready, cannot speak');
        return;
      }
      
    try {
      // Get current language
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String language = prefs.getString('tts_language') ?? 'en-US';
      
      // Make sure language is set correctly
      await _flutterTts!.setLanguage(language);
      
      // Ensure high volume and good speech rate for clear speech
      await _flutterTts!.setVolume(1.0);
      await _flutterTts!.setSpeechRate(0.5);
      
      print('Speaking text (${description.length} chars): ${description.substring(0, min(50, description.length))}...');
      
      setState(() {
        _isSpeaking = true;
      });
      
      // Handle longer text by chunking if needed
      if (description.length > 300) {
        print('Long text detected - breaking into chunks for better playback');
        // Break into sentences first
        List<String> sentences = description.split(RegExp(r'(?<=[.!?])\s+'));
        
        // Group sentences into chunks of reasonable size
        List<String> chunks = [];
        String currentChunk = '';
        
        for (String sentence in sentences) {
          if (currentChunk.length + sentence.length > 150) {
            chunks.add(currentChunk);
            currentChunk = sentence;
          } else {
            if (currentChunk.isNotEmpty) {
              currentChunk += ' ';
            }
            currentChunk += sentence;
          }
        }
        
        if (currentChunk.isNotEmpty) {
          chunks.add(currentChunk);
        }
        
        print('Speaking in ${chunks.length} chunks');
        
        // Speak each chunk with a small delay between them
        for (int i = 0; i < chunks.length; i++) {
          if (!_isSpeaking) break; // Stop if user cancelled
          
          print('Speaking chunk ${i+1}/${chunks.length}');
          var result = await _flutterTts!.speak(chunks[i].trim());
          print('TTS speak result for chunk ${i+1}: $result');
          
          // Wait for current chunk to finish
          if (Platform.isAndroid) {
            // On Android with awaitSpeakCompletion, we don't need an extra delay
          } else {
            // On iOS we need to add a delay
            await Future.delayed(Duration(milliseconds: 1000));
          }
        }
      } else {
        // For shorter texts, speak at once
      var result = await _flutterTts!.speak(description);
      print('TTS speak result: $result');
      }
    } catch (e) {
      print('Error with text-to-speech: $e');
      setState(() {
        _isSpeaking = false;
      });
      
      // Try reinitializing TTS
      try {
        print('Reinitializing TTS after error');
        await _flutterTts!.stop();
        await _initTts();
      } catch (reinitError) {
        print('Failed to reinitialize TTS: $reinitError');
      }
    }
  }

  void _showTtsSettingsDialog() async {
    if (_flutterTts == null) {
      await _initTts();
    }
    
    // Define common languages that work well with TTS
    final List<Map<String, String>> commonLanguages = [
      {'name': 'English (US)', 'code': 'en-US'},
      {'name': 'English (UK)', 'code': 'en-GB'},
      {'name': 'Hindi', 'code': 'hi-IN'},
      {'name': 'Spanish', 'code': 'es-ES'},
      {'name': 'French', 'code': 'fr-FR'},
      {'name': 'German', 'code': 'de-DE'},
      {'name': 'Italian', 'code': 'it-IT'},
      {'name': 'Japanese', 'code': 'ja-JP'},
      {'name': 'Korean', 'code': 'ko-KR'},
      {'name': 'Chinese', 'code': 'zh-CN'},
    ];
    
    // Get available voices for displaying
    List<dynamic> availableVoices = [];
    try {
      availableVoices = await _flutterTts!.getVoices;
      print('Dialog - Available voices: ${availableVoices.length}');
    } catch (e) {
      print('Error getting voices: $e');
    }
    
    // Get current settings from preferences, or use defaults
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String savedLangCode = prefs.getString('tts_language') ?? 'en-US';
    
    // Find the language name from the code
    String currentLanguage = 'English (US)';
    for (var lang in commonLanguages) {
      if (lang['code'] == savedLangCode) {
        currentLanguage = lang['name']!;
        break;
      }
    }
    
    double speechRate = prefs.getDouble('tts_speech_rate') ?? 0.5;
    double volume = prefs.getDouble('tts_volume') ?? 1.0;
    double pitch = prefs.getDouble('tts_pitch') ?? 1.0;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Speech Settings'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Language:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  DropdownButton<String>(
                    value: currentLanguage,
                    isExpanded: true,
                    items: commonLanguages.map((language) {
                      return DropdownMenuItem<String>(
                        value: language['name'],
                        child: Text(language['name']!),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          currentLanguage = value;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Speech Rate:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Slider(
                    value: speechRate,
                    min: 0.0,
                    max: 1.0,
                    divisions: 10,
                    label: speechRate.toStringAsFixed(1),
                    onChanged: (value) {
                      setState(() {
                        speechRate = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Volume:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Slider(
                    value: volume,
                    min: 0.0,
                    max: 1.0,
                    divisions: 10,
                    label: volume.toStringAsFixed(1),
                    onChanged: (value) {
                      setState(() {
                        volume = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Pitch:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Slider(
                    value: pitch,
                    min: 0.5,
                    max: 2.0,
                    divisions: 15,
                    label: pitch.toStringAsFixed(1),
                    onChanged: (value) {
                      setState(() {
                        pitch = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () async {
                      // Find the language code for the selected language
                      String langCode = 'en-US';
                      for (var lang in commonLanguages) {
                        if (lang['name'] == currentLanguage) {
                          langCode = lang['code']!;
                          break;
                        }
                      }
                      
                      // Test the current settings
                      if (_flutterTts != null) {
                        await _flutterTts!.setLanguage(langCode);
                        
                        // For Hindi specifically, we need to explicitly set a voice
                        if (langCode == 'hi-IN') {
                          var hindiVoices = availableVoices.where((voice) => 
                              voice.toString().toLowerCase().contains('hindi') || 
                              voice.toString().contains('hi-IN'));
                          
                          if (hindiVoices.isNotEmpty) {
                            print('Testing with Hindi voice: ${hindiVoices.first}');
                            await _flutterTts!.setVoice({"name": hindiVoices.first.toString(), "locale": "hi-IN"});
                          }
                        }
                        
                        await _flutterTts!.setSpeechRate(speechRate);
                        await _flutterTts!.setVolume(volume);
                        await _flutterTts!.setPitch(pitch);
                        
                        // Use a language-specific test message
                        String testMessage = "This is a test of the speech settings.";
                        if (langCode == 'hi-IN') {
                          testMessage = "यह वाक् सेटिंग्स का एक परीक्षण है।";
                        } else if (langCode == 'es-ES') {
                          testMessage = "Esta es una prueba de la configuración de voz.";
                        } else if (langCode == 'fr-FR') {
                          testMessage = "Ceci est un test des paramètres vocaux.";
                        } else if (langCode == 'de-DE') {
                          testMessage = "Dies ist ein Test der Spracheinstellungen.";
                        } else if (langCode == 'it-IT') {
                          testMessage = "Questo è un test delle impostazioni vocali.";
                        } else if (langCode == 'ja-JP') {
                          testMessage = "これは音声設定のテストです。";
                        } else if (langCode == 'ko-KR') {
                          testMessage = "이것은 음성 설정 테스트입니다.";
                        } else if (langCode == 'zh-CN') {
                          testMessage = "这是语音设置测试。";
                        }
                        
                        _flutterTts!.speak(testMessage);
                      }
                    },
                    child: const Text('Test Speech'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  // Find the language code for the selected language
                  String langCode = 'en-US';
                  for (var lang in commonLanguages) {
                    if (lang['name'] == currentLanguage) {
                      langCode = lang['code']!;
                      break;
                    }
                  }
                  
                  // Save settings
                  await _flutterTts!.setLanguage(langCode);
                  
                  // For Hindi specifically, we need to explicitly set a voice
                  if (langCode == 'hi-IN') {
                    var hindiVoices = availableVoices.where((voice) => 
                        voice.toString().toLowerCase().contains('hindi') || 
                        voice.toString().contains('hi-IN'));
                    
                    if (hindiVoices.isNotEmpty) {
                      print('Saving Hindi voice: ${hindiVoices.first}');
                      await _flutterTts!.setVoice({"name": hindiVoices.first.toString(), "locale": "hi-IN"});
                    }
                  }
                  
                  await _flutterTts!.setSpeechRate(speechRate);
                  await _flutterTts!.setVolume(volume);
                  await _flutterTts!.setPitch(pitch);
                  
                  // Save to preferences
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('tts_language', langCode);
                  await prefs.setDouble('tts_speech_rate', speechRate);
                  await prefs.setDouble('tts_volume', volume);
                  await prefs.setDouble('tts_pitch', pitch);
                  
                  Navigator.pop(context);
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Speech settings saved'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                child: const Text('Save'),
              ),
            ],
          );
        }
      ),
    );
  }

  // Add a new method to toggle adaptive intervals
  void _toggleAdaptiveIntervals() {
    setState(() {
      _adaptiveIntervalsEnabled = !_adaptiveIntervalsEnabled;
      
      // If turning on adaptive intervals, update the interval immediately
      if (_adaptiveIntervalsEnabled && _isScanning) {
        _currentScanInterval = _geminiService.getRecommendedScanningInterval();
        _startScanningTimer(); // Restart timer with new interval
      }
    });
    
    // Show confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _adaptiveIntervalsEnabled 
              ? 'Adaptive scanning enabled - will adjust based on network quality' 
              : 'Adaptive scanning disabled - using fixed interval'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
  
  // Add a widget to show the current connection quality
  Widget _buildConnectionQualityIndicator() {
    Color color;
    String label;
    
    switch (_connectivityService.quality) {
      case ConnectionQuality.offline:
        color = Colors.red;
        label = 'Offline';
        break;
      case ConnectionQuality.poor:
        color = Colors.orange;
        label = 'Poor Connection';
        break;
      case ConnectionQuality.moderate:
        color = Colors.yellow;
        label = 'Moderate';
        break;
      case ConnectionQuality.good:
        color = Colors.lightGreen;
        label = 'Good';
        break;
      case ConnectionQuality.excellent:
        color = Colors.green;
        label = 'Excellent';
        break;
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  Future<void> _initializeServices() async {
    print('Initializing services...');
    
    // Initialize TTS first thing
    await _initTts();
    
    // Only try to initialize camera if permission is granted
    if (_cameraPermissionGranted) {
      try {
        // Initialize camera
        print('Initializing camera service...');
        await _cameraService.initialize();
        print('Camera service initialized successfully');
      } catch (e) {
        print('Error initializing camera: $e');
        // Show error but continue app initialization
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Camera error: ${e.toString()}. Please restart the app.'),
              duration: Duration(seconds: 5),
              action: SnackBarAction(
                label: 'Retry',
                onPressed: () => _initCamera(),
              ),
            ),
          );
        }
      }
    } else {
      print('Camera permission not granted - skipping camera initialization');
    }
    
    // Initialize Gemini service
    await _geminiService.initialize();
    
    // Initialize connectivity service
    await _connectivityService.initialize();
    
    // Initialize speech
    _initSpeech();
    
    // Set initial scan interval based on connection quality
    _currentScanInterval = _geminiService.getRecommendedScanningInterval();
    
    if (mounted) {
      setState(() {
        // If we're mounted, update the UI
        print('Services initialized successfully');
      });
    }
    
    // Test TTS after full initialization
    if (_flutterTts != null) {
      try {
        print('Testing TTS after complete initialization');
        var result = await _flutterTts!.speak('Ready for scene description');
        print('Final TTS test result: $result');
      } catch (e) {
        print('Error in final TTS test: $e');
      }
    }
  }

  // Add method to check and request camera permission
  Future<void> _checkCameraPermission() async {
    final status = await Permission.camera.status;
    
    if (status.isGranted) {
      setState(() {
        _cameraPermissionGranted = true;
      });
      // Only initialize services if permission is granted
      _initializeServices();
    } else if (status.isDenied) {
      // Request permission
      _requestCameraPermission();
    } else if (status.isPermanentlyDenied) {
      // Show dialog to open app settings
      _showPermissionPermanentlyDeniedDialog();
    }
  }

  // Add method to request camera permission
  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    
    if (status.isGranted) {
      setState(() {
        _cameraPermissionGranted = true;
      });
      // Initialize services after permission granted
      _initializeServices();
    } else {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Camera permission is required to use this feature'),
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'Try Again',
              onPressed: _requestCameraPermission,
            ),
          ),
        );
      }
    }
  }

  // Add method to show dialog when permission is permanently denied
  void _showPermissionPermanentlyDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Camera Permission Required'),
        content: const Text(
          'Camera permission is required to use scene description features. '
          'Please enable camera access in app settings.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  // Add a method to listen for voice queries
  void _startListeningForVoiceQuery() async {
    if (_isListeningForVoiceCommand) return;
    
    setState(() {
      _isListeningForVoiceCommand = true;
    });
    
    try {
      bool available = await _speech.initialize(
        onStatus: (status) {
          if (kDebugMode) {
            print('Speech recognition status: $status');
          }
          
          if (status == 'done' || status == 'notListening') {
            setState(() {
              _isListeningForVoiceCommand = false;
            });
          }
        },
        onError: (error) {
          if (kDebugMode) {
            print('Speech recognition error: $error');
          }
          
          setState(() {
            _isListeningForVoiceCommand = false;
          });
        },
      );
      
      if (available) {
        await _speech.listen(
          onResult: (result) {
            if (result.finalResult) {
              final query = result.recognizedWords;
              
              if (query.isNotEmpty) {
                _processVoiceQuery(query);
              }
              
              setState(() {
                _isListeningForVoiceCommand = false;
              });
            }
          },
          listenFor: Duration(seconds: 10),
          pauseFor: Duration(seconds: 3),
          listenMode: stt.ListenMode.confirmation,
        );
      } else {
        setState(() {
          _isListeningForVoiceCommand = false;
          _speechAvailable = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Speech recognition is not available on this device'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error starting speech recognition: $e');
      }
      
      setState(() {
        _isListeningForVoiceCommand = false;
      });
    }
  }

  // Process voice query with the correct provider methods
  void _processVoiceQuery(String query) async {
    if (query.isEmpty) return;
    
    if (kDebugMode) {
      print('Processing voice query: $query');
    }
    
    // Stop any ongoing speech first
    await _stopSpeech();
    
    setState(() {
      _isScanning = true;
    });
    
    // Show loading state
    final provider = Provider.of<SceneDescriptionProvider>(context, listen: false);
    provider.setLoading(true);
    
    // IMPORTANT: Take a new picture first to ensure we're analyzing what the user is looking at now
    File? imageFile;
    try {
      // Take a new picture
      if (kDebugMode) {
        print('Taking new picture for voice query...');
      }
      
      // Ensure camera is initialized
      if (!_cameraService.isInitialized) {
        print('Camera not initialized, attempting to initialize...');
        try {
          await _cameraService.initialize();
          await Future.delayed(Duration(milliseconds: 500));
        } catch (e) {
          print('Failed to initialize camera: $e');
          _speakDescription("I'm sorry, the camera is not available. Please try again.");
          provider.setLoading(false);
          setState(() {
            _isScanning = false;
          });
          return;
        }
      }
      
      // Take a picture
      imageFile = await _cameraService.takePicture();
      if (imageFile == null) {
        throw Exception('Failed to capture image');
      }
      
      if (kDebugMode) {
        print('New image captured successfully for voice query: ${imageFile.path}');
      }
      
      // Save the new image in the provider
      provider.setImageFile(imageFile);
      
    } catch (e) {
      if (kDebugMode) {
        print('Error capturing image for voice query: $e');
      }
      
      _speakDescription("I'm sorry, I couldn't take a picture. Please try again.");
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error capturing image: ${e.toString()}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      
      provider.setLoading(false);
      setState(() {
        _isScanning = false;
      });
      return;
    }
    
    try {
      // Ask the question using the newly captured image
      final result = await _geminiService.askQuestionAboutImage(imageFile, query);
      
      if (result['success']) {
        final answer = result['answer'] as String;
        
        // Update UI with the answer
        setState(() {
          _currentDescription = answer;
        });
        
        // IMPORTANT: Force TTS to read the response aloud immediately
        if (kDebugMode) {
          print('Speaking voice query response: ${answer.length} chars');
        }
        
        // Add the scene to history
        provider.addScene(answer, imageFile.path);
        
        // Stop any ongoing speech
        if (_isSpeaking) {
          await _flutterTts?.stop();
          setState(() {
            _isSpeaking = false;
          });
          // Wait a moment before starting new speech
          await Future.delayed(Duration(milliseconds: 300));
        }
        
        // Speak the answer with priority
        _speakDescription(answer);
      } else {
        throw Exception(result['error']);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error processing voice query: $e');
      }
      
      // Speak the error
      _speakDescription("I'm sorry, I couldn't answer that question. Please try again.");
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      // Update provider state
      provider.setLoading(false);
      setState(() {
        _isScanning = false;
      });
    }
  }

  // Add a method to add to history
  void _addToHistory(String description, String imagePath) {
    try {
      final scene = SceneItem(
        description: description,
        timestamp: DateTime.now(),
        imagePath: imagePath,
      );
      
      _sceneHistory.add(scene);
    } catch (e) {
      print('Error adding to history: $e');
    }
  }

  // Add a method to stop current speech
  Future<void> _stopSpeech() async {
    if (_flutterTts != null && _isSpeaking) {
      try {
        print('Stopping speech manually');
        await _flutterTts!.stop();
        setState(() {
          _isSpeaking = false;
        });
      } catch (e) {
        print('Error stopping speech: $e');
      }
    }
  }
}

class SceneItem {
  final String description;
  final DateTime timestamp;
  final String? imagePath;

  SceneItem({
    required this.description,
    required this.timestamp,
    this.imagePath,
  });
} 