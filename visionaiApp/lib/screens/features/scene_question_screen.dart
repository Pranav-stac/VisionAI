import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/scene_description.dart';
import '../../providers/scene_description_provider.dart';
import '../../widgets/custom_text_field.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SceneQuestionScreen extends StatefulWidget {
  final String sceneId;
  
  const SceneQuestionScreen({super.key, required this.sceneId});

  @override
  State<SceneQuestionScreen> createState() => _SceneQuestionScreenState();
}

class _SceneQuestionScreenState extends State<SceneQuestionScreen> {
  final TextEditingController _questionController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;
  
  // Speech to text variables
  late stt.SpeechToText _speech;
  bool _isListening = false;
  bool _speechAvailable = false;
  
  @override
  void initState() {
    super.initState();
    // Set the current scene
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<SceneDescriptionProvider>(context, listen: false);
      provider.setCurrentScene(widget.sceneId);
    });
    
    // Initialize speech to text
    _speech = stt.SpeechToText();
    _initSpeech();
  }
  
  // Initialize speech recognition
  void _initSpeech() async {
    _speechAvailable = await _speech.initialize(
      onStatus: (status) => print('Speech recognition status: $status'),
      onError: (error) => print('Speech recognition error: $error'),
    );
    setState(() {});
  }
  
  // Start listening for speech with language support
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
    });
    
    // Get language preference from shared preferences
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
    
    print('Starting speech recognition with locale: $speechLocale');
    
    await _speech.listen(
      onResult: _onSpeechResult,
      listenFor: const Duration(seconds: 10),
      pauseFor: const Duration(seconds: 5),
      partialResults: true,
      localeId: speechLocale,
    );
  }
  
  // Stop listening for speech
  void _stopListening() async {
    await _speech.stop();
    setState(() {
      _isListening = false;
    });
  }
  
  // Handle speech recognition results
  void _onSpeechResult(SpeechRecognitionResult result) {
    setState(() {
      _questionController.text = result.recognizedWords;
    });
    
    // If we're done listening and have a final result, automatically submit
    if (result.finalResult && _questionController.text.isNotEmpty) {
      // Give a small delay before automatically submitting
      Future.delayed(const Duration(milliseconds: 500), () {
        _askQuestion();
      });
    }
  }
  
  @override
  void dispose() {
    _questionController.dispose();
    _scrollController.dispose();
    _speech.stop();
    super.dispose();
  }
  
  void _askQuestion() async {
    final question = _questionController.text.trim();
    if (question.isEmpty) return;
    
    setState(() {
      _isSending = true;
    });
    
    final provider = Provider.of<SceneDescriptionProvider>(context, listen: false);
    await provider.askQuestionAboutScene(question);
    
    _questionController.clear();
    setState(() {
      _isSending = false;
    });
    
    // Scroll to the bottom
    _scrollToBottom();
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
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDarkMode = theme.brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ask about this Scene'),
      ),
      body: Consumer<SceneDescriptionProvider>(
        builder: (context, provider, child) {
          final currentScene = provider.currentScene;
          final isLoading = provider.isLoading;
          final error = provider.error;
          
          if (currentScene == null) {
            return const Center(
              child: Text('Scene not found'),
            );
          }
          
          final questions = currentScene.questions ?? [];
          
          return Column(
            children: [
              // Scene Image and Description
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Scene Image
                    if (currentScene.imagePath != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          provider.currentImageFile!,
                          height: 150,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    const SizedBox(height: 12),
                    // Scene Description
                    const Text(
                      'Scene Description:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      currentScene.description,
                      style: const TextStyle(
                        fontSize: 14,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () {
                        // Show full description in a dialog
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Scene Description'),
                            content: SingleChildScrollView(
                              child: Text(currentScene.description),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Close'),
                              ),
                            ],
                          ),
                        );
                      },
                      child: const Text('Read Full Description'),
                    ),
                  ],
                ),
              ),
              
              // Questions List
              Expanded(
                child: questions.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.question_answer_outlined,
                              size: 80,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Ask a question about this scene',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Example: "How many people are in this scene?"\n"What objects can you see?"\n"Is there any text visible?"',
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
                        padding: const EdgeInsets.all(16),
                        itemCount: questions.length,
                        itemBuilder: (context, index) {
                          final question = questions[index];
                          return _buildQuestionItem(question);
                        },
                      ),
              ),
              
              // Error Message
              if (error != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  color: Colors.red[50],
                  child: Text(
                    error,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.red[800],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              
              // Question Input
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
                child: Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        controller: _questionController,
                        hintText: _isListening 
                          ? 'Listening...' 
                          : 'Ask a question about this scene...',
                        labelText: 'Question',
                        prefixIcon: Icons.question_answer,
                        enabled: !isLoading && !_isSending && !_isListening,
                        onSubmitted: (_) => _askQuestion(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Microphone button
                    IconButton(
                      onPressed: !isLoading && !_isSending
                          ? (_isListening ? _stopListening : _startListening)
                          : null,
                      icon: Icon(
                        _isListening ? Icons.mic_off : Icons.mic,
                        color: _isListening 
                          ? Colors.red 
                          : colorScheme.primary,
                      ),
                      tooltip: _isListening 
                        ? 'Stop listening' 
                        : 'Ask with voice',
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: (_questionController.text.isNotEmpty && !isLoading && !_isSending && !_isListening)
                          ? _askQuestion
                          : null,
                      icon: const Icon(Icons.send),
                      color: colorScheme.primary,
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
  
  Widget _buildQuestionItem(SceneQuestion question) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDarkMode = theme.brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.person,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'You',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _formatTime(question.timestamp),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  question.question,
                  style: const TextStyle(
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Answer
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[800] : Colors.white,
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
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
                Row(
                  children: [
                    Icon(
                      Icons.smart_toy,
                      size: 16,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'AI',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  question.answer,
                  style: const TextStyle(
                    fontSize: 16,
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
} 