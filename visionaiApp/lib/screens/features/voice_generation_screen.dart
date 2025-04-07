import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';

class VoiceGenerationScreen extends StatefulWidget {
  const VoiceGenerationScreen({super.key});

  @override
  State<VoiceGenerationScreen> createState() => _VoiceGenerationScreenState();
}

class _VoiceGenerationScreenState extends State<VoiceGenerationScreen> {
  final TextEditingController _textController = TextEditingController();
  bool _isSpeaking = false;
  FlutterTts? _flutterTts;
  String _selectedLanguage = 'en-US';
  double _speechRate = 0.5;
  double _volume = 1.0;
  double _pitch = 1.0;
  List<dynamic> _availableVoices = [];
  
  // Quick phrases
  final List<String> _commonPhrases = [
    "Hello",
    "Thank you",
    "Yes",
    "No",
    "Please",
    "Excuse me",
    "Help me",
    "I need water",
    "I need food",
    "I'm not feeling well",
    "Call someone",
    "What time is it?",
    "Where is the bathroom?",
    "My name is...",
    "Nice to meet you",
  ];
  
  // Recent phrases
  List<String> _recentPhrases = [];
  
  // Categories for organized phrases
  final Map<String, List<String>> _phraseCategories = {
    "Greetings": ["Hello", "Good morning", "Good afternoon", "Good evening", "How are you?", "Nice to meet you"],
    "Basic Needs": ["I need water", "I need food", "I need to rest", "I need medicine", "I need to use the bathroom"],
    "Emergency": ["Help me", "Call an ambulance", "I'm not feeling well", "Emergency", "Pain", "Call my family"],
    "Feelings": ["I'm happy", "I'm sad", "I'm tired", "I'm uncomfortable", "I'm cold", "I'm hot"],
    "Responses": ["Yes", "No", "Maybe", "Not sure", "Thank you", "You're welcome", "Please", "Sorry"],
  };

  // Favorite phrases
  Set<String> _favoritePhrases = {};

  @override
  void initState() {
    super.initState();
    _initTts();
    _loadSavedPhrases();
  }

  Future<void> _loadSavedPhrases() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _recentPhrases = prefs.getStringList('recent_phrases') ?? [];
      _favoritePhrases = Set<String>.from(prefs.getStringList('favorite_phrases') ?? []);
    });
  }

  Future<void> _saveRecentPhrase(String phrase) async {
    if (phrase.isEmpty) return;
    
    // Add to recent phrases, remove duplicates and limit to 15
    setState(() {
      _recentPhrases.remove(phrase);
      _recentPhrases.insert(0, phrase);
      if (_recentPhrases.length > 15) {
        _recentPhrases = _recentPhrases.sublist(0, 15);
      }
    });
    
    // Save to preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('recent_phrases', _recentPhrases);
  }

  Future<void> _toggleFavorite(String phrase) async {
    setState(() {
      if (_favoritePhrases.contains(phrase)) {
        _favoritePhrases.remove(phrase);
      } else {
        _favoritePhrases.add(phrase);
      }
    });
    
    // Save to preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('favorite_phrases', _favoritePhrases.toList());
  }

  @override
  void dispose() {
    _textController.dispose();
    _flutterTts?.stop();
    super.dispose();
  }

  Future<void> _initTts() async {
    _flutterTts = FlutterTts();
    
    // Get saved settings or use defaults
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String language = prefs.getString('tts_language') ?? 'en-US';
    double speechRate = prefs.getDouble('tts_speech_rate') ?? 0.5;
    double volume = prefs.getDouble('tts_volume') ?? 1.0;
    double pitch = prefs.getDouble('tts_pitch') ?? 1.0;
    
    // Debug: Print all available languages and voices
    try {
      var availableLanguages = await _flutterTts!.getLanguages;
      print('Available TTS languages: $availableLanguages');
      
      _availableVoices = await _flutterTts!.getVoices;
      print('Available TTS voices: ${_availableVoices.length}');
      
      // First set language to ensure it's supported
      await _flutterTts!.setLanguage(language);
      
      // For Hindi specifically, explicitly set voice if we can find one
      if (language == 'hi-IN') {
        var hindiVoice = _availableVoices.where((voice) => 
            voice.toString().toLowerCase().contains('hindi') || 
            voice.toString().contains('hi-IN'));
        
        if (hindiVoice.isNotEmpty) {
          print('Setting Hindi voice: ${hindiVoice.first}');
          await _flutterTts!.setVoice({"name": hindiVoice.first.toString(), "locale": "hi-IN"});
        }
      }
      
      setState(() {
        _selectedLanguage = language;
        _speechRate = speechRate;
        _volume = volume;
        _pitch = pitch;
      });
    } catch (e) {
      print('Error setting TTS language: $e');
      // Fallback to English if there's an error
      await _flutterTts!.setLanguage('en-US');
      setState(() {
        _selectedLanguage = 'en-US';
      });
    }
    
    await _flutterTts!.setSpeechRate(speechRate);
    await _flutterTts!.setVolume(volume);
    await _flutterTts!.setPitch(pitch);
    
    // Configure error and completion handlers
    _flutterTts!.setStartHandler(() {
      print('TTS started speaking');
    setState(() {
      _isSpeaking = true;
      });
    });
    
    _flutterTts!.setCompletionHandler(() {
      setState(() {
        _isSpeaking = false;
        print('TTS completed speaking');
      });
    });
    
    _flutterTts!.setErrorHandler((error) {
      print('TTS error: $error');
      setState(() {
        _isSpeaking = false;
      });
      
      // Show error to user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Speech error: $error'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    });
    
    print('TTS initialized with language: $language, rate: $speechRate');
  }

  void _speak([String? text]) async {
    final textToSpeak = text ?? _textController.text;
    if (textToSpeak.isEmpty) return;
    
    // Save to recent phrases
    _saveRecentPhrase(textToSpeak);
    
    if (_isSpeaking) {
      // If already speaking, stop
      await _flutterTts!.stop();
      setState(() {
        _isSpeaking = false;
      });
      return;
    }
    
    try {
      print('Speaking text: $textToSpeak');
      print('With language: $_selectedLanguage');
      
      // Make sure language is set correctly
      await _flutterTts!.setLanguage(_selectedLanguage);
      
      // For Hindi specifically, try to set the voice directly
      if (_selectedLanguage == 'hi-IN') {
        try {
          var hindiVoice = _availableVoices.where((voice) => 
              voice.toString().toLowerCase().contains('hindi') || 
              voice.toString().contains('hi-IN'));
          
          if (hindiVoice.isNotEmpty) {
            print('Setting Hindi voice before speaking: ${hindiVoice.first}');
            await _flutterTts!.setVoice({"name": hindiVoice.first.toString(), "locale": "hi-IN"});
          }
        } catch (e) {
          print('Error setting Hindi voice: $e');
        }
      }
      
      await _flutterTts!.setSpeechRate(_speechRate);
      await _flutterTts!.setVolume(_volume);
      await _flutterTts!.setPitch(_pitch);
      
      setState(() {
        _isSpeaking = true;
      });
      
      // Speak the text
      var result = await _flutterTts!.speak(textToSpeak);
      print('TTS speak result: $result');
      // The _isSpeaking will be set to false by the completion handler
    } catch (e) {
      print('Error with text-to-speech: $e');
      setState(() {
        _isSpeaking = false;
      });
      
      // Show error to user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Speech error: ${e.toString()}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
  
  void _addToTextField(String phrase) {
    final currentText = _textController.text;
    if (currentText.isEmpty) {
      _textController.text = phrase;
    } else {
      // Add a space if needed
      _textController.text = '$currentText ${phrase.toLowerCase()}';
    }
    
    // Move cursor to the end
    _textController.selection = TextSelection.fromPosition(
      TextPosition(offset: _textController.text.length),
    );
  }
  
  Widget _buildPhraseChip(String phrase) {
    final isFavorite = _favoritePhrases.contains(phrase);
    
    return Container(
      margin: const EdgeInsets.only(right: 8, bottom: 8),
      child: ActionChip(
        backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
        label: Text(
          phrase,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSecondaryContainer,
          ),
        ),
        avatar: isFavorite ? Icon(
          Icons.star,
          size: 16,
          color: Theme.of(context).colorScheme.onSecondaryContainer,
        ) : null,
        onPressed: () => _speak(phrase),
        // Double tap to add to text field
        tooltip: 'Tap to speak, double tap to add to text field',
      ),
    );
  }
  
  Widget _buildPhraseButton(String phrase) {
    final isFavorite = _favoritePhrases.contains(phrase);
    
    return GestureDetector(
      onTap: () => _speak(phrase),
      onDoubleTap: () => _addToTextField(phrase),
      onLongPress: () => _toggleFavorite(phrase),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        margin: const EdgeInsets.only(right: 8, bottom: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(20),
          border: isFavorite ? Border.all(
            color: Theme.of(context).colorScheme.primary,
            width: 2,
          ) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isFavorite) 
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Icon(
                  Icons.star,
                  size: 14,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            Text(
              phrase,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSecondaryContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _showPhraseCategoriesDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return DefaultTabController(
              length: _phraseCategories.keys.length + 2, // Categories + Favorites + Recent
              child: Column(
                children: [
                  Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  TabBar(
                    isScrollable: true,
                    tabs: [
                      const Tab(text: "Favorites"),
                      const Tab(text: "Recent"),
                      ..._phraseCategories.keys.map((category) => Tab(text: category)).toList(),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        // Favorites tab
                        _favoritePhrases.isEmpty
                          ? const Center(child: Text("No favorite phrases yet.\nLong press any phrase to add it to favorites."))
                          : Padding(
                              padding: const EdgeInsets.all(16),
                              child: Wrap(
                                children: _favoritePhrases
                                    .toList()
                                    .map((phrase) => _buildPhraseButton(phrase))
                                    .toList(),
                              ),
                            ),
                        
                        // Recent tab
                        _recentPhrases.isEmpty
                          ? const Center(child: Text("No recent phrases yet."))
                          : Padding(
                              padding: const EdgeInsets.all(16),
                              child: Wrap(
                                children: _recentPhrases
                                    .map((phrase) => _buildPhraseButton(phrase))
                                    .toList(),
                              ),
                            ),
                        
                        // Category tabs
                        ..._phraseCategories.values.map(
                          (phrases) => Padding(
                            padding: const EdgeInsets.all(16),
                            child: Wrap(
                              children: phrases
                                  .map((phrase) => _buildPhraseButton(phrase))
                                  .toList(),
                            ),
                          ),
                        ).toList(),
                      ],
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
    
    // Find current language name from code
    String currentLanguage = 'English (US)';
    for (var lang in commonLanguages) {
      if (lang['code'] == _selectedLanguage) {
        currentLanguage = lang['name']!;
        break;
      }
    }
    
    double speechRate = _speechRate;
    double volume = _volume;
    double pitch = _pitch;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Voice Settings'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Language:'),
                  const SizedBox(height: 8),
                  DropdownButton<String>(
                    value: currentLanguage,
                    isExpanded: true,
                    items: commonLanguages.map((lang) {
                      return DropdownMenuItem<String>(
                        value: lang['name'],
                        child: Text(lang['name']!),
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
                  const Text('Speech Rate:'),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text('Slow', style: TextStyle(fontSize: 12)),
                      Text('Fast', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Volume:'),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text('Quiet', style: TextStyle(fontSize: 12)),
                      Text('Loud', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Pitch:'),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text('Low', style: TextStyle(fontSize: 12)),
                      Text('High', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: ElevatedButton(
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
                            var hindiVoices = _availableVoices.where((voice) => 
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
                    var hindiVoices = _availableVoices.where((voice) => 
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
                  
                  // Update state
                  this.setState(() {
                    _selectedLanguage = langCode;
                    _speechRate = speechRate;
                    _volume = volume;
                    _pitch = pitch;
                  });
                  
                  Navigator.pop(context);
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Voice settings saved'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Voice Generation'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showTtsSettingsDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
              child: _isSpeaking
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.volume_up,
                          size: 50,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text('Speaking...'),
                      const SizedBox(height: 8),
                      Text(
                        'Language: ${_getLanguageName(_selectedLanguage)}',
                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                  )
                : Column(
                  children: [
                    // Quick access to favorites
                    if (_favoritePhrases.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        width: double.infinity,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(bottom: 8),
                              child: Text(
                                'Favorites',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Wrap(
                              children: _favoritePhrases
                                  .take(6) // Limit to 6 favorites
                                  .map((phrase) => _buildPhraseChip(phrase))
                                  .toList(),
                            ),
                          ],
                        ),
                      ),
                    
                    // Common phrases
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      width: double.infinity,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Quick Phrases',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              TextButton(
                                onPressed: _showPhraseCategoriesDialog,
                                child: const Text('See All'),
                              ),
                            ],
                          ),
                          Wrap(
                            children: _commonPhrases
                                .take(10) // Limit to 10 phrases
                                .map((phrase) => _buildPhraseChip(phrase))
                                .toList(),
                          ),
                        ],
                      ),
                    ),
                    
                    // Recent phrases
                    if (_recentPhrases.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        width: double.infinity,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(bottom: 8),
                              child: Text(
                                'Recent',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Wrap(
                              children: _recentPhrases
                                  .take(6) // Limit to 6 recent phrases
                                  .map((phrase) => _buildPhraseChip(phrase))
                                  .toList(),
                            ),
                          ],
                        ),
                      ),
                      
                    // Instructions
                    Expanded(
                      child: Center(
                        child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.record_voice_over,
                              size: 60,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 32),
                              child: Text(
                                'Tap a phrase to speak it immediately',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Current language: ${_getLanguageName(_selectedLanguage)}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                      ),
                    ),
                  ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.brightness == Brightness.light
                  ? Colors.white
                  : Colors.grey[900],
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
                Row(
                  children: [
                    // Quick action buttons
                    IconButton(
                      icon: const Icon(Icons.category),
                      onPressed: _showPhraseCategoriesDialog,
                      tooltip: 'Phrase categories',
                    ),
                    IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => _textController.clear(),
                      tooltip: 'Clear text',
                    ),
                    // Text field
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: theme.brightness == Brightness.light
                          ? Colors.grey[100]
                          : Colors.grey[800],
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: TextField(
                      controller: _textController,
                      decoration: const InputDecoration(
                            hintText: 'Type or select a message...',
                        border: InputBorder.none,
                      ),
                      maxLines: 1,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _speak(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                    // Speak button
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(
                      _isSpeaking ? Icons.stop : Icons.volume_up,
                      color: Colors.white,
                    ),
                        onPressed: () => _speak(),
                      ),
                  ),
                  ],
                ),
                // Word suggestions will go here in the future
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  String _getLanguageName(String code) {
    switch (code) {
      case 'en-US': return 'English (US)';
      case 'en-GB': return 'English (UK)';
      case 'hi-IN': return 'Hindi';
      case 'es-ES': return 'Spanish';
      case 'fr-FR': return 'French';
      case 'de-DE': return 'German';
      case 'it-IT': return 'Italian';
      case 'ja-JP': return 'Japanese';
      case 'ko-KR': return 'Korean';
      case 'zh-CN': return 'Chinese';
      default: return code;
    }
  }
} 