import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;

class ImageCaptioningScreen extends StatefulWidget {
  const ImageCaptioningScreen({super.key});

  @override
  State<ImageCaptioningScreen> createState() => _ImageCaptioningScreenState();
}

class _ImageCaptioningScreenState extends State<ImageCaptioningScreen> with WidgetsBindingObserver {
  bool _isListening = false;
  final List<CaptionItem> _captions = [];
  final ScrollController _scrollController = ScrollController();
  
  // Speech to text variables
  late stt.SpeechToText _speech;
  bool _speechAvailable = false;
  String _currentVoiceText = '';
  String _speechLocale = 'en_US';
  
  // Image generation variables
  String? _generatedImageUrl;
  bool _isGeneratingImage = false;
  String _lastProcessedText = '';
  
  // Continuous streaming variables
  Timer? _streamProcessTimer;
  int _minWordsForProcessing = 5;
  int _streamProcessDelay = 1000; // milliseconds
  
  // Reliability tracking
  int _restartAttempts = 0;
  static const int _maxRestartAttempts = 5;
  DateTime? _lastRestartTime;
  
  // New variables for the improved restart strategy
  bool _restartPending = false;
  
  // Add these new variables for improved error handling
  int _timeoutCount = 0;
  int _noMatchCount = 0;
  Timer? _cooldownTimer;
  bool _inCooldownPeriod = false;
  
  // Update these constants for smoother operation
  static const int _cooldownDuration = 3; // In seconds, reduced from 5
  static const int _listenDuration = 30; // Longer listen duration
  static const int _pauseForDuration = 4; // Longer pause tolerance

  // Modify these variables at the class level
  bool _processingCompleteSentence = false;
  List<String> _completeUtterances = [];
  String _currentSentenceBuffer = '';

  // Add this variable to better track consecutive errors
  int _consecutiveErrorCount = 0;
  String _bufferedSpeech = ''; // Buffer to collect speech across restarts

  // Add these variables to track speech activity
  DateTime? _lastSpeechTime;
  bool _isSpeaking = false;
  Timer? _speechPauseTimer;
  int _silenceDurationMs = 1200; // Wait this long after speech stops before processing

  // Add these variables at the class level
  DateTime _lastProcessTime = DateTime.now().subtract(Duration(days: 1));
  bool _isProcessingText = false;

  @override
  void initState() {
    super.initState();
    // Add app lifecycle observer
    WidgetsBinding.instance.addObserver(this);
    // Initialize speech recognition
    _speech = stt.SpeechToText();
    _initSpeech();
    _loadPreferences();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _speech.stop();
    _scrollController.dispose();
    _streamProcessTimer?.cancel();
    _listeningMonitorTimer?.cancel();
    _backupTimer?.cancel();
    _cooldownTimer?.cancel(); // Dispose new timer
    super.dispose();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Handle app being paused or resumed
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      if (_isListening) {
        _stopListening();
      }
    } else if (state == AppLifecycleState.resumed) {
      if (_isListening) {
        _startListening();
      }
    }
  }
  
  // Initialize speech recognition
  void _initSpeech() async {
    _speechAvailable = await _speech.initialize(
      onStatus: (status) {
        print('Speech recognition status: $status');
        
        if (status == 'listening') {
          print('✅ Speech recognition is now actively listening');
          // Reset error counters when successfully listening
          _noMatchCount = 0;
          _consecutiveErrorCount = 0;
        }
        else if (status == 'done' || status == 'notListening') {
          print('⚠️ Speech recognition stopped - status: $status');
          
          if (_isListening && !_inCooldownPeriod && !_restartPending) {
            // Schedule a quick restart
            print('Scheduling quick restart to maintain continuous listening');
            _scheduleRestart(300); // Very quick restart
          }
        }
      },
      onError: (errorNotification) {
        print('❌ Speech recognition error: ${errorNotification.errorMsg}, permanent: ${errorNotification.permanent}');
        
        _consecutiveErrorCount++;
        
        // Different handling based on error type
        if (errorNotification.errorMsg == 'error_no_match') {
          _noMatchCount++;
          print('No speech match detected. Count: $_noMatchCount');
          
          // For no-match errors, try a very quick restart
          if (_isListening && !_inCooldownPeriod && !_restartPending) {
            int delayMs = 200; // Very small delay for no-match errors
            print('Quick restart for no-match error');
            _scheduleRestart(delayMs);
          }
        }
        else if (_isListening && !_inCooldownPeriod && !_restartPending) {
          // For other errors, use a progressive delay strategy
          int delayMs = 300 * (_consecutiveErrorCount > 3 ? 3 : _consecutiveErrorCount);
          _scheduleRestart(delayMs);
        }
        
        // Enter cooldown only after many consecutive errors
        if (_consecutiveErrorCount > 8) {
          _enterCooldownMode('Taking a short break after multiple errors');
          // Reset counter
          _consecutiveErrorCount = 0;
        }
      },
    );
    setState(() {});
  }
  
  // Schedule a restart with specific delay and tracking
  void _scheduleRestart(int delayMs) {
    if (_restartPending || _inCooldownPeriod) {
      print('Restart already pending or in cooldown, ignoring new request');
      return;
    }
    
    _restartPending = true;
    print('Scheduling restart in ${delayMs}ms (attempt #${_restartAttempts + 1})');
    
    Future.delayed(Duration(milliseconds: delayMs), () {
      _forceRestart();
      _restartPending = false;
    });
  }
  
  // Force a complete restart of speech recognition 
  void _forceRestart() {
    // Cancel existing timers first
    _backupTimer?.cancel();
    _listeningMonitorTimer?.cancel();
    
    // Track restart attempts
    _restartAttempts++;
    _lastRestartTime = DateTime.now();
    
    // Progressively increase pause between restarts, but keep it relatively short
    int pauseDuration = 100 * _restartAttempts;
    if (pauseDuration > 800) pauseDuration = 800; // cap at 800ms
    
    print('Forcing restart with ${pauseDuration}ms delay (attempt #$_restartAttempts)');
    
    // Stop the current speech recognition session
    _speech.stop().then((_) {
      // If user turned off listening during restart, don't continue
      if (!_isListening) {
        print('User stopped listening during restart, aborting');
        return;
      }
      
      // Enforced pause to let the system recover
      Future.delayed(Duration(milliseconds: pauseDuration), () {
        if (_isListening && !_inCooldownPeriod) {
          // Reset counter if it's been a while since last restart
          if (_lastRestartTime != null && 
              DateTime.now().difference(_lastRestartTime!).inSeconds > 15) {
            print('Resetting restart attempt counter - been a while since last restart');
            _restartAttempts = 0;
          }
          
          // Force cooldown if we've been restarting too much
          if (_restartAttempts > _maxRestartAttempts) {
            _enterCooldownMode('Too many restart attempts, taking a break');
            return;
          }
          
          // Start fresh recognition
          _startSpeechRecognition();
        }
      });
    }).catchError((e) {
      print('Error stopping speech for restart: $e');
      Future.delayed(Duration(milliseconds: pauseDuration + 200), () {
        if (_isListening && !_inCooldownPeriod) {
          _startSpeechRecognition();
        }
      });
    });
  }
  
  // Start listening without changing _isListening state
  void _startSpeechRecognition() {
    if (_inCooldownPeriod) {
      print('In cooldown period, not starting recognition');
      return;
    }
    
    try {
      print('Starting fresh speech recognition');
      _speech.listen(
        onResult: _onSpeechResult,
        listenFor: Duration(seconds: _listenDuration), // Longer session
        pauseFor: Duration(seconds: _pauseForDuration), // Longer pause tolerance
        partialResults: true,
        localeId: _speechLocale,
        listenMode: stt.ListenMode.dictation,
        cancelOnError: false,
      );
      
      // Set up monitoring but with less frequent checks
      _createListeningMonitor();
      
    } catch (e) {
      print('Error in _startSpeechRecognition: $e');
      if (_restartAttempts >= _maxRestartAttempts - 1) {
        _enterCooldownMode('Unable to start listening');
      } else {
        Future.delayed(const Duration(milliseconds: 800), () {
          if (_isListening && !_inCooldownPeriod) {
            _scheduleRestart(600);
          }
        });
      }
    }
  }
  
  // Load user preferences
  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _speechLocale = prefs.getString('speech_locale') ?? 'en_US';
      // Load user preference for word count if available
      _minWordsForProcessing = prefs.getInt('min_words_for_processing') ?? 2;
      _streamProcessDelay = prefs.getInt('stream_process_delay') ?? 1000;
    });
  }

  void _toggleListening() {
    if (_isListening) {
      _stopListening();
    } else {
      // Reset all control variables
      _restartAttempts = 0;
      _timeoutCount = 0;
      _noMatchCount = 0;
      _inCooldownPeriod = false;
      _cooldownTimer?.cancel();
      
      _startListening();
    }
  }

  // Timer for backup listening check
  Timer? _backupTimer;
  
  void _startListening() async {
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
    
    // Cancel any existing timers
    _streamProcessTimer?.cancel();
    _listeningMonitorTimer?.cancel();
    _backupTimer?.cancel();
    _cooldownTimer?.cancel();
    
    setState(() {
      _isListening = true;
      _currentVoiceText = '';
      _restartAttempts = 0;
      _restartPending = false;
      _inCooldownPeriod = false;
      
      // Clear deduplication history
      _lastProcessedText = '';
      _lastProcessTime = DateTime.now().subtract(Duration(days: 1));
      _isProcessingText = false;
    });
    
    // Setup timer for continuous processing
    _streamProcessTimer = Timer.periodic(
      const Duration(milliseconds: 2000),
      (timer) {
        // Just do nothing, or you can put any other monitoring code here
        if (_isListening && _currentVoiceText.isNotEmpty) {
          // Maybe log something if needed
          // print('Current text: $_currentVoiceText');
        }
      },
    );
    
    // Create a backup timer that keeps checking if we need to restart
    _backupTimer = Timer.periodic(
      const Duration(seconds: 2), // Check less frequently to reduce system load
      (timer) {
        if (_isListening && !_speech.isListening && !_restartPending && !_inCooldownPeriod) {
          print('Backup timer detected speech not listening');
          _scheduleRestart(300); // Quick restart when backup timer detects issue
        }
      }
    );
    
    // Start speech recognition
    _startSpeechRecognition();
  }
  
  void _stopListening() async {
    _streamProcessTimer?.cancel();
    _listeningMonitorTimer?.cancel();
    _backupTimer?.cancel();
    
    setState(() {
      _isListening = false;
    });
    
    try {
      await _speech.stop();
      print('Stopped listening successfully');
    } catch (e) {
      print('Error stopping speech recognition: $e');
    }
    
    // Process one last time if needed
    if (_currentVoiceText.isNotEmpty && _currentVoiceText != _lastProcessedText) {
      _generateImageFromText(_currentVoiceText);
    }
  }
  
  // Replace the entire speech processing flow with this streamlined approach
  void _onSpeechResult(SpeechRecognitionResult result) {
    // Check if we're still supposed to be listening
    if (!_isListening) return;
    
    final String recognizedText = result.recognizedWords;
    
    // Always update displayed text
    setState(() {
      _currentVoiceText = recognizedText;
    });
    
    // Only process final results
    if (result.finalResult && recognizedText.isNotEmpty) {
      print('📝 Final speech result: "$recognizedText"');
      
      // Critical check: Only process if text is different AND enough time has passed
      if (_shouldProcessText(recognizedText)) {
        _processRecognizedText(recognizedText);
      } else {
        print('🚫 BLOCKING DUPLICATE: "$recognizedText"');
      }
    }
  }
  
  // New method to centralize duplicate checking
  bool _shouldProcessText(String text) {
    // Empty check
    if (text.isEmpty) return false;
    
    // Too similar to last processed text
    if (_textIsSimilar(text, _lastProcessedText)) {
      // Calculate time since last process
      final timeSince = DateTime.now().difference(_lastProcessTime).inSeconds;
      
      // If we processed a similar text recently, block it
      if (timeSince < 10) { // Increased to 10 seconds for stricter blocking
        print('⏱️ Only ${timeSince}s since last similar text was processed');
        return false;
      }
    }
    
    // If we're currently processing, block new requests
    if (_isProcessingText) {
      print('⚙️ Currently processing another text, blocking this one');
      return false;
    }
    
    return true;
  }
  
  // New method to check if texts are similar
  bool _textIsSimilar(String text1, String text2) {
    // Exact match
    if (text1 == text2) return true;
    
    // Clean both texts
    final clean1 = text1.toLowerCase().trim();
    final clean2 = text2.toLowerCase().trim();
    
    // Exact match after cleaning
    if (clean1 == clean2) return true;
    
    // If one contains the other
    if (clean1.contains(clean2) || clean2.contains(clean1)) return true;
    
    // Split into words and count matching words
    final words1 = clean1.split(' ').where((w) => w.isNotEmpty).toList();
    final words2 = clean2.split(' ').where((w) => w.isNotEmpty).toList();
    
    // Count matching words
    int matchingWords = 0;
    for (var word in words1) {
      if (words2.contains(word)) matchingWords++;
    }
    
    // If 75% of words match, consider them similar
    final similarity = matchingWords / math.max(words1.length, words2.length);
    return similarity > 0.75;
  }
  
  // Create a centralized processing method
  Future<void> _processRecognizedText(String text) async {
    // Guard to prevent processing empty text or during cooldown
    if (text.isEmpty || _inCooldownPeriod) return;
    
    // Set processing flag to block other attempts
    _isProcessingText = true;
    
    // Log processing
    print('');
    print('🔄 PROCESSING TEXT: "$text"');
    print('📅 Last processed: "${_lastProcessedText}" (${DateTime.now().difference(_lastProcessTime).inSeconds}s ago)');
    print('');
    
    // Update tracking variables
    _lastProcessedText = text;
    _lastProcessTime = DateTime.now();
    
    // Add to captions for UI
    setState(() {
      _captions.add(
        CaptionItem(
          text: text,
          timestamp: DateTime.now(),
          speaker: 'User',
          isPartial: false,
        ),
      );
    });
    
    _scrollToBottom();
    
    // Generate image
    await _generateImageFromText(text);
    
    // Clear processing flag
    _isProcessingText = false;
  }
  
  // Update the image generation method to be simpler
  Future<void> _generateImageFromText(String text) async {
    if (text.isEmpty || _isGeneratingImage) return;
    
    setState(() {
      _isGeneratingImage = true;
    });
    
    print('🖼️ GENERATING IMAGE FOR: "$text"');
    
    try {
      final response = await http.post(
        Uri.parse("https://pranavai.onrender.com/generate"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "prompt": text
        }),
      );
      
      print('API Response Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        
        if (result.containsKey('images') && result['images'].isNotEmpty) {
          final imageData = result['images'][0];
          
          if (imageData.containsKey('url') && imageData['url'].toString().startsWith('data:image')) {
            setState(() {
              _generatedImageUrl = imageData['url'];
            });
            
            print('✅ Successfully generated image for: "$text"');
          }
        }
      } else {
        print('❌ Image generation failed: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error generating image: $e');
    }
    
    setState(() {
      _isGeneratingImage = false;
    });
  }
  
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _clearCaptions() {
    setState(() {
      _captions.clear();
      _generatedImageUrl = null;
    });
  }

  void _showLanguageSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    final Map<String, String> languageOptions = {
      'English (US)': 'en_US',
      'English (UK)': 'en_GB',
      'Hindi': 'hi_IN',
      'Spanish': 'es_ES',
      'French': 'fr_FR',
      'German': 'de_DE',
    };
    
    // Find current language name from code
    String currentLanguage = 'English (US)';
    languageOptions.forEach((name, code) {
      if (code == _speechLocale) {
        currentLanguage = name;
      }
    });

    // Settings for streaming parameters
    int wordCount = _minWordsForProcessing;
    int delayMs = _streamProcessDelay;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Settings'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Recognition Language:'),
                const SizedBox(height: 8),
                DropdownButton<String>(
                  value: currentLanguage,
                  isExpanded: true,
                  items: languageOptions.keys.map((name) {
                    return DropdownMenuItem<String>(
                      value: name,
                      child: Text(name),
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
                const Text('Minimum Words For Processing:'),
                Slider(
                  value: wordCount.toDouble(),
                  min: 1,
                  max: 5,
                  divisions: 4,
                  label: wordCount.toString(),
                  onChanged: (value) {
                    setState(() {
                      wordCount = value.round();
                    });
                  },
                ),
                Text('Process after ${wordCount.toString()} words'),
                
                const SizedBox(height: 16),
                const Text('Processing Delay (ms):'),
                Slider(
                  value: delayMs.toDouble(),
                  min: 500,
                  max: 2000,
                  divisions: 6,
                  label: delayMs.toString(),
                  onChanged: (value) {
                    setState(() {
                      delayMs = value.round();
                    });
                  },
                ),
                Text('Check every ${(delayMs / 1000).toStringAsFixed(1)} seconds'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  final code = languageOptions[currentLanguage] ?? 'en_US';
                  await prefs.setString('speech_locale', code);
                  await prefs.setInt('min_words_for_processing', wordCount);
                  await prefs.setInt('stream_process_delay', delayMs);
                  
                  if (mounted) {
                    setState(() {
                      _speechLocale = code;
                      _minWordsForProcessing = wordCount;
                      _streamProcessDelay = delayMs;
                    });
                    Navigator.pop(context);
                    
                    // Update timer if it's running
                    if (_streamProcessTimer != null && _streamProcessTimer!.isActive) {
                      _streamProcessTimer!.cancel();
                      _streamProcessTimer = Timer.periodic(
                        Duration(milliseconds: delayMs), 
                        (timer) => {/* Do nothing */}
                      );
                    }
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Settings saved'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  // Timer to monitor if listening stopped unexpectedly
  Timer? _listeningMonitorTimer;
  
  void _createListeningMonitor() {
    _listeningMonitorTimer?.cancel();
    
    // Check every 2 seconds which is less frequent
    _listeningMonitorTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (_isListening && !_speech.isListening && !_restartPending && !_inCooldownPeriod) {
        print('Monitor detected listening stopped unexpectedly');
        _scheduleRestart(400);
      }
    });
  }

  // New method for cooldown mode
  void _enterCooldownMode(String reason) {
    if (_inCooldownPeriod) return;
    
    print('Entering cooldown mode: $reason');
    _inCooldownPeriod = true;
    
    // Stop active listening
    _speech.stop();
    
    // Show user feedback
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Taking a short break. $reason'),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
      
      // Update UI to show we're paused but not stopped
      setState(() {
        // We're still "listening" from the user's perspective
        // but we're taking a break from actual recognition
      });
    }
    
    // Set a cooldown timer
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer(const Duration(seconds: 5), () {
      if (mounted && _isListening) {
        print('Cooldown period over, restarting speech recognition');
        _inCooldownPeriod = false;
        _restartAttempts = 0;
        _timeoutCount = 0;
        _noMatchCount = 0;
        
        // Start fresh recognition
        _startSpeechRecognition();
        
        // Show user feedback
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Listening resumed'),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        _inCooldownPeriod = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Speech to Image'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: _showLanguageSettings,
          ),
        ],
      ),
      body: Column(
        children: [
          // Caption Display Area
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.brightness == Brightness.light
                    ? Colors.grey[100]
                    : Colors.grey[900],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  // Speech status indicator - replace with new method
                  _buildStatusIndicator(),
                  
                  // Generated Image Section
                  if (_generatedImageUrl != null || _isGeneratingImage)
                    Container(
                      height: 250, // Increased height 
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: theme.brightness == Brightness.light
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
                      child: _isGeneratingImage
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const CircularProgressIndicator(),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Creating your image...',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: _generatedImageUrl != null
                                  ? Image.memory(
                                      base64Decode(_generatedImageUrl!.split(',')[1]),
                                      fit: BoxFit.cover,
                                    )
                                  : const SizedBox(),
                            ),
                    ),
                  
                  // Captions
                  Expanded(
                    child: _captions.isEmpty && _currentVoiceText.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.mic_none,
                                size: 80,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Tap the microphone and start describing an image',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Images will be generated in real-time as you speak',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          itemCount: _captions.length,
                          padding: const EdgeInsets.only(bottom: 16),
                          itemBuilder: (context, index) {
                            final caption = _captions[index];
                            // Alternate sides based on index
                            final isLeftSide = index % 2 == 0;
                            
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Row(
                                mainAxisAlignment: isLeftSide
                                    ? MainAxisAlignment.start
                                    : MainAxisAlignment.end,
                                children: [
                                  if (isLeftSide)
                                    CircleAvatar(
                                      backgroundColor: Colors.blue[100],
                                      radius: 16,
                                      child: Text(
                                        '${index + 1}',
                                        style: TextStyle(
                                          color: Colors.blue[800],
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isLeftSide
                                            ? Colors.blue[50]
                                            : Colors.green[50],
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.05),
                                            blurRadius: 5,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                        // Add a special border for partial results
                                        border: caption.isPartial
                                            ? Border.all(
                                                color: Colors.grey.withOpacity(0.3),
                                                width: 1,
                                                style: BorderStyle.solid,
                                              )
                                            : null,
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            caption.text,
                                            style: TextStyle(
                                              fontSize: 16,
                                              color: isLeftSide
                                                  ? Colors.blue[800]
                                                  : Colors.green[800],
                                              fontStyle: caption.isPartial
                                                  ? FontStyle.italic
                                                  : FontStyle.normal,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                _formatTime(caption.timestamp),
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                              if (caption.isPartial) ...[
                                                const SizedBox(width: 4),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 6, 
                                                    vertical: 2
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey[200],
                                                    borderRadius: BorderRadius.circular(10),
                                                  ),
                                                  child: Text(
                                                    'processing',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      color: Colors.grey[600],
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  if (!isLeftSide)
                                    CircleAvatar(
                                      backgroundColor: Colors.green[100],
                                      radius: 16,
                                      child: Text(
                                        '${index + 1}',
                                        style: TextStyle(
                                          color: Colors.green[800],
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                  ),
                  
                  // Display current voice text while listening
                  if (_isListening && _currentVoiceText.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(top: 8),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: colorScheme.primary.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        _currentVoiceText,
                        style: TextStyle(
                          fontSize: 16,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Microphone Control Panel
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              children: [
                // Control Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_captions.isNotEmpty || _generatedImageUrl != null)
                      Container(
                        width: 60,
                        height: 60,
                        margin: const EdgeInsets.only(right: 16),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: Icon(
                            Icons.delete_outline,
                            color: Colors.red[400],
                            size: 28,
                          ),
                          onPressed: _clearCaptions,
                        ),
                      ),
                    GestureDetector(
                      onTap: _toggleListening,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: _isListening
                              ? Colors.red
                              : colorScheme.primary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: _isListening
                                  ? Colors.red.withOpacity(0.3)
                                  : colorScheme.primary.withOpacity(0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                              spreadRadius: 3,
                            ),
                          ],
                        ),
                        child: Icon(
                          _isListening ? Icons.stop : Icons.mic,
                          color: Colors.white,
                          size: 36,
                        ),
                      ),
                    ),
                    if (_generatedImageUrl != null)
                      Container(
                        width: 60,
                        height: 60,
                        margin: const EdgeInsets.only(left: 16),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: Icon(
                            Icons.share,
                            color: Colors.blue[400],
                            size: 28,
                          ),
                          onPressed: () {
                            // Share image
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Sharing not implemented yet'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                // Status Text
                Text(
                  _isListening
                      ? 'Listening & generating in real-time...'
                      : 'Tap to start listening',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final hour = timestamp.hour.toString().padLeft(2, '0');
    final minute = timestamp.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  // Update UI status display to show if in cooldown
  Widget _buildStatusIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: _isListening
            ? (_inCooldownPeriod 
                ? Colors.orange.withOpacity(0.1)
                : Colors.green.withOpacity(0.1))
            : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _isListening
              ? (_inCooldownPeriod
                  ? Colors.orange.withOpacity(0.3)
                  : Colors.green.withOpacity(0.3))
              : Colors.grey.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _isListening
                ? (_inCooldownPeriod ? Icons.timer : Icons.mic)
                : Icons.mic_off,
            size: 16,
            color: _isListening
                ? (_inCooldownPeriod ? Colors.orange : Colors.green)
                : Colors.grey,
          ),
          const SizedBox(width: 6),
          Text(
            _isListening
                ? (_inCooldownPeriod
                    ? 'Paused (resuming soon...)'
                    : 'Listening continuously')
                : 'Microphone off',
            style: TextStyle(
              fontSize: 12,
              color: _isListening
                  ? (_inCooldownPeriod ? Colors.orange : Colors.green)
                  : Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class CaptionItem {
  final String text;
  final DateTime timestamp;
  final String speaker;
  final bool isPartial;

  CaptionItem({
    required this.text,
    required this.timestamp,
    required this.speaker,
    this.isPartial = false,
  });
} 