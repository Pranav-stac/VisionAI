import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CaptioningScreen extends StatefulWidget {
  const CaptioningScreen({super.key});

  @override
  State<CaptioningScreen> createState() => _CaptioningScreenState();
}

class _CaptioningScreenState extends State<CaptioningScreen> {
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
  Timer? _imageGenerationTimer;
  String _lastProcessedText = '';

  @override
  void initState() {
    super.initState();
    // Initialize speech recognition
    _speech = stt.SpeechToText();
    _initSpeech();
    _loadPreferences();
  }

  @override
  void dispose() {
    _speech.stop();
    _scrollController.dispose();
    _imageGenerationTimer?.cancel();
    super.dispose();
  }
  
  // Initialize speech recognition
  void _initSpeech() async {
    _speechAvailable = await _speech.initialize(
      onStatus: (status) => print('Speech recognition status: $status'),
      onError: (error) => print('Speech recognition error: $error'),
    );
    setState(() {});
  }
  
  // Load user preferences
  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _speechLocale = prefs.getString('speech_locale') ?? 'en_US';
    });
  }

  void _toggleListening() {
    if (_isListening) {
      _stopListening();
    } else {
      _startListening();
    }
  }

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
    
    setState(() {
      _isListening = true;
      _currentVoiceText = '';
    });
    
    // Set up timer for image generation
    _imageGenerationTimer = Timer.periodic(
      const Duration(seconds: 5), 
      (timer) {
        if (_currentVoiceText.isNotEmpty && _currentVoiceText != _lastProcessedText) {
          _generateImageFromText(_currentVoiceText);
          _lastProcessedText = _currentVoiceText;
        }
      }
    );
    
    await _speech.listen(
      onResult: _onSpeechResult,
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      partialResults: true,
      localeId: _speechLocale,
      listenMode: stt.ListenMode.confirmation,
    );
  }
  
  void _stopListening() async {
    await _speech.stop();
    _imageGenerationTimer?.cancel();
    setState(() {
      _isListening = false;
    });
  }
  
  // Handle speech recognition results
  void _onSpeechResult(SpeechRecognitionResult result) {
    setState(() {
      _currentVoiceText = result.recognizedWords;
      
      // Add a new caption if this is a final result
      if (result.finalResult) {
        if (_currentVoiceText.isNotEmpty) {
          _captions.add(
            CaptionItem(
              text: _currentVoiceText,
              timestamp: DateTime.now(),
              speaker: 'User',
            ),
          );
          
          // Generate image from the final text
          _generateImageFromText(_currentVoiceText);
          _lastProcessedText = _currentVoiceText;
          
          // Auto-scroll to the bottom
          _scrollToBottom();
          
          // Reset for the next utterance but continue listening
          _currentVoiceText = '';
          
          // Restart listening if we're still in listening mode
          if (_isListening && !_speech.isListening) {
            _startListening();
          }
        }
      }
    });
  }
  
  // Generate image from text using the API
  Future<void> _generateImageFromText(String text) async {
    if (text.isEmpty || _isGeneratingImage) return;
    
    setState(() {
      _isGeneratingImage = true;
    });
    
    try {
      final response = await http.post(
        Uri.parse("https://pranavai.onrender.com/generate"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "prompt": text
        }),
      );
      
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        
        if (result.containsKey('images') && result['images'].isNotEmpty) {
          final imageData = result['images'][0];
          
          if (imageData.containsKey('url') && imageData['url'].toString().startsWith('data:image')) {
            setState(() {
              _generatedImageUrl = imageData['url'];
              _isGeneratingImage = false;
            });
            return;
          }
        }
      }
      
      print('Failed to generate image: ${response.statusCode} - ${response.body}');
    } catch (e) {
      print('Error generating image: $e');
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

  void _saveCaptions() {
    // In a real app, you would save the captions to a file or database
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Captions saved successfully'),
        behavior: SnackBarBehavior.floating,
      ),
    );
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
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Language Settings'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Select Recognition Language:'),
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
                  
                  if (mounted) {
                    setState(() {
                      _speechLocale = code;
                    });
                    Navigator.pop(context);
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Language settings saved'),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Real-Time Captioning'),
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
                  // Generated Image Section
                  if (_generatedImageUrl != null || _isGeneratingImage)
                    Container(
                      height: 200,
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
                                    'Generating image...',
                                    style: TextStyle(
                                      fontSize: 14,
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
                                'Tap the microphone button to start captioning',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Images will be generated from your speech',
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
                            final isCurrentUser = caption.speaker == 'User';
                            
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Row(
                                mainAxisAlignment: isCurrentUser
                                    ? MainAxisAlignment.end
                                    : MainAxisAlignment.start,
                                children: [
                                  if (!isCurrentUser)
                                    CircleAvatar(
                                      backgroundColor: Colors.blue[100],
                                      radius: 16,
                                      child: Text(
                                        caption.speaker[0],
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
                                        color: isCurrentUser
                                            ? colorScheme.primary
                                            : theme.brightness == Brightness.light
                                                ? Colors.white
                                                : Colors.grey[800],
                                        borderRadius: BorderRadius.circular(20),
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
                                          Text(
                                            caption.text,
                                            style: TextStyle(
                                              fontSize: 16,
                                              color: isCurrentUser
                                                  ? colorScheme.onPrimary
                                                  : theme.brightness == Brightness.light
                                                      ? Colors.black
                                                      : Colors.white,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _formatTime(caption.timestamp),
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: isCurrentUser
                                                  ? colorScheme.onPrimary.withOpacity(0.7)
                                                  : Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  if (isCurrentUser)
                                    CircleAvatar(
                                      backgroundColor: Colors.green[100],
                                      radius: 16,
                                      child: Text(
                                        caption.speaker[0],
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

          // Control Panel
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              children: [
                // Caption Settings
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildSettingButton(
                      icon: Icons.text_fields,
                      label: 'Font Size',
                      onTap: () {
                        // Open font size settings
                      },
                    ),
                    _buildSettingButton(
                      icon: Icons.color_lens,
                      label: 'Theme',
                      onTap: () {
                        // Open theme settings
                      },
                    ),
                    _buildSettingButton(
                      icon: Icons.language,
                      label: 'Language',
                      onTap: _showLanguageSettings,
                    ),
                    _buildSettingButton(
                      icon: Icons.save_alt,
                      label: 'Save',
                      onTap: _saveCaptions,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Microphone Button
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
                          },
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                // Status Text
                Text(
                  _isListening
                      ? 'Listening... Tap to stop'
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

  Widget _buildSettingButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.light
                    ? Colors.grey[100]
                    : Colors.grey[800],
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
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

  String _formatTime(DateTime timestamp) {
    final hour = timestamp.hour.toString().padLeft(2, '0');
    final minute = timestamp.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class CaptionItem {
  final String text;
  final DateTime timestamp;
  final String speaker;

  CaptionItem({
    required this.text,
    required this.timestamp,
    required this.speaker,
  });
} 