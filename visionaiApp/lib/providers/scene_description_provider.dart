import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/scene_description.dart';
import '../services/openai_service.dart';

class SceneDescriptionProvider with ChangeNotifier {
  final OpenAIService _openAIService = OpenAIService();
  List<SceneDescription> _sceneHistory = [];
  SceneDescription? _currentScene;
  bool _isLoading = false;
  String? _error;
  File? _currentImageFile;
  bool _isLiveMode = true;
  
  // Getters
  List<SceneDescription> get sceneHistory => _sceneHistory;
  SceneDescription? get currentScene => _currentScene;
  bool get isLoading => _isLoading;
  String? get error => _error;
  File? get currentImageFile => _currentImageFile;
  bool get isLiveMode => _isLiveMode;
  
  // Initialize provider
  Future<void> init() async {
    await _loadSceneHistory();
  }
  
  // Set the image file
  void setImageFile(File imageFile) {
    _currentImageFile = imageFile;
    notifyListeners();
  }
  
  // Toggle between live and single scan modes
  void toggleMode() {
    _isLiveMode = !_isLiveMode;
    notifyListeners();
  }
  
  // Set loading state
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  // Add a new scene with description and image path
  Future<SceneDescription> addScene(String description, String imagePath) async {
    final newScene = SceneDescription(
      id: const Uuid().v4(),
      description: description,
      timestamp: DateTime.now(),
      imagePath: imagePath,
      analysisResults: {},
      questions: [],
    );
    
    _currentScene = newScene;
    _sceneHistory.add(newScene);
    _currentImageFile = File(imagePath);
    
    await _saveSceneHistory();
    notifyListeners();
    
    return newScene;
  }
  
  // Generate a description for the current image
  Future<void> generateDescription() async {
    if (_currentImageFile == null) {
      _error = 'No image available for analysis';
      notifyListeners();
      return;
    }
    
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      // Call OpenAI API to analyze the image
      final result = await _openAIService.generateSceneDescription(_currentImageFile!);
      
      if (result['success']) {
        // Save the image file
        final savedImagePath = await _saveImageFile(_currentImageFile!);
        
        // Create a new scene description
        final newScene = SceneDescription(
          id: const Uuid().v4(),
          description: result['description'],
          timestamp: DateTime.now(),
          imagePath: savedImagePath,
          analysisResults: {},
          questions: [],
        );
        
        // Update state
        _currentScene = newScene;
        _sceneHistory.add(newScene);
        await _saveSceneHistory();
      } else {
        _error = result['error'];
      }
    } catch (e) {
      _error = 'Error generating description: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Analyze for specific information (text, people, hazards, etc.)
  Future<void> analyzeSceneForInfo(String infoType) async {
    if (_currentScene == null || _currentImageFile == null) {
      _error = 'No current scene to analyze';
      notifyListeners();
      return;
    }
    
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final result = await _openAIService.analyzeSceneForInfo(_currentImageFile!, infoType);
      
      if (result['success']) {
        // Update the current scene with the analysis result
        // Check for 'answer' key first (new API format), then fallback to 'analysis' (old format)
        final analysisText = result['answer'] ?? result['analysis'] ?? 'No analysis available';
        
        _currentScene = _currentScene!.addAnalysisResult(infoType, analysisText);
        
        // Update scene in history
        final index = _sceneHistory.indexWhere((scene) => scene.id == _currentScene!.id);
        if (index >= 0) {
          _sceneHistory[index] = _currentScene!;
        }
        
        await _saveSceneHistory();
      } else {
        _error = result['error'];
      }
    } catch (e) {
      _error = 'Error analyzing scene: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Ask a question about the current scene
  Future<void> askQuestionAboutScene(String question) async {
    if (_currentScene == null || _currentImageFile == null) {
      _error = 'No current scene to ask about';
      notifyListeners();
      return;
    }
    
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final result = await _openAIService.askQuestionAboutImage(_currentImageFile!, question);
      
      if (result['success']) {
        // Create a new question
        final sceneQuestion = SceneQuestion(
          question: question,
          answer: result['answer'],
          timestamp: DateTime.now(),
        );
        
        // Update the current scene with the new question
        _currentScene = _currentScene!.addQuestion(sceneQuestion);
        
        // Update scene in history
        final index = _sceneHistory.indexWhere((scene) => scene.id == _currentScene!.id);
        if (index >= 0) {
          _sceneHistory[index] = _currentScene!;
        }
        
        await _saveSceneHistory();
      } else {
        _error = result['error'];
      }
    } catch (e) {
      _error = 'Error asking question: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Get a specific scene by ID
  SceneDescription? getSceneById(String id) {
    return _sceneHistory.firstWhere((scene) => scene.id == id, orElse: () => null as SceneDescription);
  }
  
  // Set a specific scene as the current scene
  void setCurrentScene(String id) {
    _currentScene = getSceneById(id);
    if (_currentScene?.imagePath != null) {
      _currentImageFile = File(_currentScene!.imagePath!);
    }
    notifyListeners();
  }
  
  // Clear history
  Future<void> clearHistory() async {
    _sceneHistory = [];
    _currentScene = null;
    _currentImageFile = null;
    await _saveSceneHistory();
    notifyListeners();
  }
  
  // Save the current image file to device storage
  Future<String> _saveImageFile(File imageFile) async {
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final path = '${directory.path}/scene_$timestamp.jpg';
    final savedImage = await imageFile.copy(path);
    return savedImage.path;
  }
  
  // Save scene history to local storage
  Future<void> _saveSceneHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sceneHistoryData = _sceneHistory.map((scene) => scene.toMap()).toList();
      await prefs.setString('scene_history', sceneHistoryData.toString());
    } catch (e) {
      if (kDebugMode) {
        print('Error saving scene history: $e');
      }
    }
  }
  
  // Load scene history from local storage
  Future<void> _loadSceneHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? sceneHistoryString = prefs.getString('scene_history');
      
      if (sceneHistoryString != null && sceneHistoryString.isNotEmpty) {
        final List<dynamic> sceneHistoryData = sceneHistoryString as List<dynamic>;
        _sceneHistory = sceneHistoryData
            .map((sceneData) => SceneDescription.fromMap(sceneData as Map<String, dynamic>))
            .toList();
        
        // Sort history by timestamp (newest first)
        _sceneHistory.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading scene history: $e');
      }
      _sceneHistory = [];
    }
    
    notifyListeners();
  }
} 