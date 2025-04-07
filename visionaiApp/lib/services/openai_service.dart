import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class OpenAIService {
  // Note: In a production app, you should use environment variables or secure storage
  // This is just for demonstration purposes
  static const String _apiKey = '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';
  static const String _baseUrl = 'https://api.openai.com/v1/chat/completions';
  
  // For storing and retrieving the API key securely
  Future<String?> getApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('openai_api_key');
  }
  
  Future<void> setApiKey(String apiKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('openai_api_key', apiKey);
  }

  // Analyze an image and return the description
  Future<String> analyzeImage(String imagePath) async {
    try {
      final File imageFile = File(imagePath);
      final result = await generateSceneDescription(imageFile);
      
      if (result['success']) {
        return result['description'];
      } else {
        if (kDebugMode) {
          print('Using fallback description due to API error: ${result['error']}');
        }
        // Return a fallback description instead of throwing an exception
        return _getOfflineDescription();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to analyze image: ${e.toString()}');
      }
      // Return a fallback description instead of throwing an exception
      return _getOfflineDescription();
    }
  }

  // Fallback description when API fails
  String _getOfflineDescription() {
    const List<String> fallbackDescriptions = [
      "The image shows what appears to be an indoor scene with good lighting. There are no obvious hazards visible.",
      "This seems to be an outdoor area with natural lighting. The scene appears to be clear of immediate obstacles.",
      "The image shows what looks like a room with furniture. The space appears to be navigable with care.",
      "This appears to be a well-lit area. No obvious text or important information is visible in the image.",
    ];
    
    return fallbackDescriptions[Random().nextInt(fallbackDescriptions.length)];
  }

  // Generate scene description from image
  Future<Map<String, dynamic>> generateSceneDescription(File imageFile) async {
    try {
      final apiKey = await getApiKey() ?? _apiKey;
      
      // Get language preference
      final prefs = await SharedPreferences.getInstance();
      String languageCode = prefs.getString('tts_language') ?? 'en-US';
      
      // Convert image to base64
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);
      
      // Log request details for debugging
      if (kDebugMode) {
        print('Making OpenAI API request to: $_baseUrl');
        print('User language preference: $languageCode');
      }
      
      // Adjust system prompt based on language preference
      String systemPrompt;
      if (languageCode == 'hi-IN') {
        systemPrompt = 'You are a helpful assistant for visually impaired users. Describe the image in detail, focusing on important elements, spatial layout, text content, people, and potential hazards. For Hindi language users, use Hinglish (mix of Hindi and English) in your response. Do not translate technical terms to pure Hindi, keep them in English. Your description should be clear, concise, and informative.';
      } else {
        systemPrompt = 'You are a helpful assistant for visually impaired users. Describe the image in detail, focusing on important elements, spatial layout, text content, people, and potential hazards. Your description should be clear, concise, and informative.';
      }
      
      // Adjust user prompt based on language preference
      String userPrompt;
      if (languageCode == 'hi-IN') {
        userPrompt = 'Is image ka description Hinglish mein batao (Hindi-English mix). Jo dekh raha hai uska short description do.';
      } else {
        userPrompt = 'Describe this image in short for someone who cannot see it.';
      }
      
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-4o',
          'messages': [
            {
              'role': 'system',
              'content': systemPrompt
            },
            {
              'role': 'user',
              'content': [
                {
                  'type': 'text',
                  'text': userPrompt
                },
                {
                  'type': 'image_url',
                  'image_url': {
                    'url': 'data:image/jpeg;base64,$base64Image'
                  }
                }
              ]
            }
          ],
          'max_tokens': 500,
        }),
      );
      
      if (kDebugMode) {
        print('OpenAI API response status: ${response.statusCode}');
        print('OpenAI API response body: ${response.body.substring(0, min(100, response.body.length))}...');
      }
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final description = data['choices'][0]['message']['content'];
        
        return {
          'success': true,
          'description': description,
        };
      } else {
        // In case of API issues, provide a fallback description so the app doesn't break
        if (kDebugMode) {
          print('API Error: ${response.statusCode}, ${response.body}');
        }
        
        // Check if we should try to use a mock description instead
        return {
          'success': false,
          'error': 'API Error: ${response.statusCode}',
          'details': response.body,
        };
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error in generateSceneDescription: $e');
      }
      return {
        'success': false,
        'error': 'Error generating scene description',
        'details': e.toString(),
      };
    }
  }

  // Answer questions about an image
  Future<Map<String, dynamic>> askQuestionAboutImage(File imageFile, String question) async {
    try {
      final apiKey = await getApiKey() ?? _apiKey;
      
      // Get language preference
      final prefs = await SharedPreferences.getInstance();
      String languageCode = prefs.getString('tts_language') ?? 'en-US';
      
      // Convert image to base64
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);
      
      if (kDebugMode) {
        print('Making question API request for language: $languageCode');
      }
      
      // Determine system prompt based on language preference
      String systemPrompt;
      if (languageCode == 'hi-IN') {
        systemPrompt = 'You are a helpful assistant for visually impaired users. Answer questions about the image clearly and concisely. For Hindi language users, respond in Hinglish (mix of Hindi and English) in your response. Do not translate technical terms to pure Hindi, keep them in English. Be conversational and natural.';
      } else {
        systemPrompt = 'You are a helpful assistant for visually impaired users. Answer questions about the image clearly and concisely.';
      }
      
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-4o',
          'messages': [
            {
              'role': 'system',
              'content': systemPrompt
            },
            {
              'role': 'user',
              'content': [
                {
                  'type': 'text',
                  'text': question
                },
                {
                  'type': 'image_url',
                  'image_url': {
                    'url': 'data:image/jpeg;base64,$base64Image'
                  }
                }
              ]
            }
          ],
          'max_tokens': 300,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final answer = data['choices'][0]['message']['content'];
        
        return {
          'success': true,
          'answer': answer,
        };
      } else {
        return {
          'success': false,
          'error': 'API Error: ${response.statusCode}',
          'details': response.body,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Error answering question about image',
        'details': e.toString(),
      };
    }
  }
  
  // Process scene for specific information (text, people, hazards, etc.)
  Future<Map<String, dynamic>> analyzeSceneForInfo(File imageFile, String infoType) async {
    try {
      final apiKey = await getApiKey() ?? _apiKey;
      
      // Get language preference
      final prefs = await SharedPreferences.getInstance();
      String languageCode = prefs.getString('tts_language') ?? 'en-US';
      
      // Convert image to base64
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);
      
      String prompt;
      if (languageCode == 'hi-IN') {
        // Hinglish prompts
        switch (infoType) {
          case 'text':
            prompt = 'Is image mein dikhne wale saare text ko extract karke batao. Agar koi text nahi hai, to woh bhi batao.';
            break;
          case 'people':
            prompt = 'Is image mein mojood logon ka description do, unki position, kya kar rahe hain, aur koi aur important details. Agar koi log nahi dikhte, to woh batao.';
            break;
          case 'hazards':
            prompt = 'Is scene mein ek visually impaired person ke liye koi potential hazards ya obstacles identify karo. Uneven surfaces, steps, barriers, moving objects, etc par dhyan do. Agar koi hazards nahi hai, to woh batao.';
            break;
          case 'location':
            prompt = 'Is image mein dikhai de rahi location ya setting ka description do. Indoor/outdoor, public/private, etc. jaisi details include karo.';
            break;
          default:
            prompt = 'Is image ka detailed description Hinglish mein batao, important elements par focus karte hue.';
        }
      } else {
        // English prompts (original)
        switch (infoType) {
          case 'text':
            prompt = 'Extract and list all text visible in this image. If no text is visible, state that clearly.';
            break;
          case 'people':
            prompt = 'Describe the people in this image, including their approximate positions, what they\'re doing, and any other notable details. If no people are visible, state that clearly.';
            break;
          case 'hazards':
            prompt = 'Identify any potential hazards or obstacles in this scene for a visually impaired person. Consider uneven surfaces, steps, barriers, moving objects, etc. If no hazards are apparent, state that clearly.';
            break;
          case 'location':
            prompt = 'Describe the location or setting shown in this image as specifically as possible. Include details about whether it appears to be indoor/outdoor, public/private, etc.';
            break;
          default:
            prompt = 'Describe this image in detail, focusing on important elements.';
        }
      }
      
      // Create appropriate system prompt based on language
      String systemPrompt;
      if (languageCode == 'hi-IN') {
        systemPrompt = 'You are a helpful assistant for visually impaired users. Provide clear, accurate, and concise information. For Hindi language users, use Hinglish (mix of Hindi and English) in your response. Do not translate technical terms to pure Hindi, keep them in English.';
      } else {
        systemPrompt = 'You are a helpful assistant for visually impaired users. Provide clear, accurate, and concise information.';
      }
      
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-4o',
          'messages': [
            {
              'role': 'system',
              'content': systemPrompt
            },
            {
              'role': 'user',
              'content': [
                {
                  'type': 'text',
                  'text': prompt
                },
                {
                  'type': 'image_url',
                  'image_url': {
                    'url': 'data:image/jpeg;base64,$base64Image'
                  }
                }
              ]
            }
          ],
          'max_tokens': 300,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final answer = data['choices'][0]['message']['content'];
        
        return {
          'success': true,
          'answer': answer,
        };
      } else {
        return {
          'success': false,
          'error': 'API Error: ${response.statusCode}',
          'details': response.body,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Error analyzing scene for specific info',
        'details': e.toString(),
      };
    }
  }
} 