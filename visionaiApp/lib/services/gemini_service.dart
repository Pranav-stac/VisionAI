import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../services/image_utils.dart';
import '../services/connectivity_service.dart';

class GeminiService {
  // Replace with your API key
  static const String _apiKey = 'AIzaSyAcFNAa__qnnYFeYn10xOGoNOyUEfxBteY'; // Get your key from https://makersuite.google.com/app/apikey
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta';
  static const String _model = 'gemini-2.0-flash';
  
  // Keep track of API response time to adjust processing intervals
  int _lastResponseTimeMs = 500;
  DateTime _lastApiCallTime = DateTime.now();
  int _consecutiveErrors = 0;
  
  // Connectivity service to adjust compression based on network quality
  final ConnectivityService _connectivityService = ConnectivityService();
  
  // For storing and retrieving the API key securely
  Future<String?> getApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('gemini_api_key') ?? _apiKey;
  }
  
  Future<void> setApiKey(String apiKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('gemini_api_key', apiKey);
  }
  
  // Initialize service
  Future<void> initialize() async {
    await _connectivityService.initialize();
  }

  // Helper method to clean up response text
  String _cleanupResponseText(String text) {
    // Remove markdown formatting
    String cleaned = text;
    
    // Remove asterisks used for bold/italic formatting
    cleaned = cleaned.replaceAll('**', '').replaceAll('*', '');
    
    // Remove any code block markers
    cleaned = cleaned.replaceAll('```', '');
    
    // Remove any common API response prefixes
    List<String> prefixesToRemove = [
      "I can see",
      "Here's what I can see:",
      "Okay, here's",
      "Sure, here's",
      "Here's a detailed description of the scenery around you",
      "Based on what I can see,",
      "I notice that",
      "I can identify",
      "I observe",
    ];
    
    for (var prefix in prefixesToRemove) {
      if (cleaned.toLowerCase().startsWith(prefix.toLowerCase())) {
        cleaned = cleaned.substring(prefix.length).trim();
      }
    }
    
    // Strip any phrases following a generic pattern like "Here's a description of the image:"
    RegExp genericPrefixPattern = RegExp(r"^(here['']s|this is|i see|i can see|looking at|as i can see|from what i can see|based on the image|the image shows) .{0,30}(image|picture|photo|scene).*?[:,]", caseSensitive: false);
    
    var match = genericPrefixPattern.firstMatch(cleaned);
    if (match != null) {
      cleaned = cleaned.substring(match.end).trim();
    }
    
    // Replace multiple spaces with a single space
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ');
    
    // Capitalize first letter if it's not already
    if (cleaned.isNotEmpty && cleaned[0].toLowerCase() == cleaned[0]) {
      cleaned = cleaned[0].toUpperCase() + cleaned.substring(1);
    }
    
    return cleaned;
  }

  // Analyze an image and return the description
  Future<String> analyzeImage(String imagePath) async {
    try {
      final File imageFile = File(imagePath);
      
      // Update connection quality before processing
      _updateConnectionQuality();
      
      // Compress image based on connection quality
      final compressedImage = await _compressImageBasedOnNetworkQuality(imageFile);
      
      // Record start time for response time tracking
      _lastApiCallTime = DateTime.now();
      
      final result = await generateSceneDescription(compressedImage);
      
      // Calculate and store response time
      _lastResponseTimeMs = DateTime.now().difference(_lastApiCallTime).inMilliseconds;
      if (kDebugMode) {
        print('API response time: $_lastResponseTimeMs ms');
      }
      
      // Reset error counter on success
      _consecutiveErrors = 0;
      
      if (result['success']) {
        return _cleanupResponseText(result['description']);
      } else {
        if (kDebugMode) {
          print('API error: ${result['error']}');
        }
        _consecutiveErrors++;
        // Instead of using fallback descriptions, throw an exception 
        // to let the caller handle the error appropriately
        throw Exception('Failed to get description: ${result['error']}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to analyze image: ${e.toString()}');
      }
      _consecutiveErrors++;
      // Rethrow the exception instead of using fallback descriptions
      throw Exception('Failed to analyze image: ${e.toString()}');
    }
  }
  
  // Compress image based on network quality
  Future<File> _compressImageBasedOnNetworkQuality(File imageFile) async {
    try {
      final quality = _connectivityService.getRecommendedImageQuality();
      final dimensions = _connectivityService.getRecommendedImageDimensions();
      
      if (kDebugMode) {
        print('Compressing image with quality: $quality, dimensions: ${dimensions['width']}x${dimensions['height']}');
      }
      
      // First resize the image
      final resizedImage = await ImageUtils.resizeImage(
        imageFile, 
        width: dimensions['width'] ?? 800, 
        height: dimensions['height'] ?? 600
      );
      
      // Then compress it
      final compressedImage = await ImageUtils.compressImage(
        resizedImage ?? imageFile, 
        quality: quality
      );
      
      return compressedImage ?? imageFile;
    } catch (e) {
      if (kDebugMode) {
        print('Error compressing image: $e');
      }
      return imageFile;
    }
  }
  
  // Update connection quality estimate based on recent API performance
  void _updateConnectionQuality() {
    // If we've had multiple consecutive errors, downgrade our connection quality estimate
    if (_consecutiveErrors > 2) {
      // Adjust connection quality based on errors
    }
    
    // If recent responses have been slow, adjust our quality estimate
    if (_lastResponseTimeMs > 3000) {
      // Slow responses indicate poor connection
    }
  }

  // Generate scene description from image with adaptive prompt optimization based on network quality
  Future<Map<String, dynamic>> generateSceneDescription(File imageFile) async {
    try {
      final apiKey = await getApiKey();
      
      // Get language preference
      final prefs = await SharedPreferences.getInstance();
      String languageCode = prefs.getString('tts_language') ?? 'en-US';
      
      // Convert image to base64
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);
      
      // Log request details for debugging
      if (kDebugMode) {
        print('Making Gemini API request to: $_baseUrl/models/$_model:generateContent');
        print('User language preference: $languageCode');
        print('Image size: ${bytes.length} bytes');
      }
      
      // Optimize prompt length based on network quality
      String systemPrompt;
      if (_connectivityService.quality == ConnectionQuality.poor || 
          _connectivityService.quality == ConnectionQuality.offline) {
        // Shorter prompt for poor connections
        if (languageCode == 'hi-IN') {
          systemPrompt = 'Is image mein kya hai? Short mein batao.';
        } else {
          systemPrompt = 'Briefly describe this image for someone who cannot see it.';
        }
      } else {
        // Full prompt for better connections
        if (languageCode == 'hi-IN') {
          systemPrompt = 'You are a helpful assistant for visually impaired users. Describe this image in detail in Hinglish (mix of Hindi and English), focusing on important elements, spatial layout, text content, people, and potential hazards. Keep technical terms in English. Be clear, concise, and informative.';
        } else {
          systemPrompt = 'You are a helpful assistant for visually impaired users. Describe this image in detail, focusing on important elements, spatial layout, text content, people, and potential hazards. Be clear, concise, and informative.';
        }
      }
      
      // Set token limit based on connection quality
      int maxTokens;
      switch (_connectivityService.quality) {
        case ConnectionQuality.excellent:
          maxTokens = 500;
          break;
        case ConnectionQuality.good:
          maxTokens = 400;
          break;
        case ConnectionQuality.moderate:
          maxTokens = 300;
          break;
        case ConnectionQuality.poor:
        case ConnectionQuality.offline:
          maxTokens = 200;
          break;
      }
      
      // Add retry mechanism
      int maxRetries = 2;
      int retryCount = 0;
      
      while (retryCount <= maxRetries) {
        try {
          final response = await http.post(
            Uri.parse('$_baseUrl/models/$_model:generateContent?key=$apiKey'),
            headers: {
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'contents': [
                {
                  'parts': [
                    {
                      'text': systemPrompt
                    },
                    {
                      'inline_data': {
                        'mime_type': 'image/jpeg',
                        'data': base64Image
                      }
                    }
                  ]
                }
              ],
              'generation_config': {
                'max_output_tokens': maxTokens,
                'temperature': 0.4,
                'top_p': 0.95,
                'top_k': 40
              },
            }),
          ).timeout(const Duration(seconds: 30));
          
          if (kDebugMode) {
            print('Gemini API response status: ${response.statusCode}');
            print('Gemini API response body length: ${response.body.length}');
          }
          
          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            
            // Check for the expected data structure
            if (data.containsKey('candidates') && 
                data['candidates'].isNotEmpty && 
                data['candidates'][0].containsKey('content') &&
                data['candidates'][0]['content'].containsKey('parts') &&
                data['candidates'][0]['content']['parts'].isNotEmpty) {
              
              final description = data['candidates'][0]['content']['parts'][0]['text'];
              
              if (description != null && description.isNotEmpty) {
                return {
                  'success': true,
                  'description': description,
                };
              }
            }
            
            // Handle the response format that only contains usageMetadata
            // This occurs when the model hasn't generated a response yet or is not authorized
            if (data.containsKey('usageMetadata') && data.containsKey('modelVersion')) {
              // Try the fallback Gemini model
              if (retryCount == 0) {
                retryCount++;
                if (kDebugMode) {
                  print('Received metadata-only response. Trying fallback model...');
                }
                
                // Modify the model and try again
                final fallbackModel = 'gemini-pro-vision';
                final fallbackResponse = await http.post(
                  Uri.parse('$_baseUrl/models/$fallbackModel:generateContent?key=$apiKey'),
                  headers: {
                    'Content-Type': 'application/json',
                  },
                  body: jsonEncode({
                    'contents': [
                      {
                        'parts': [
                          {
                            'text': systemPrompt
                          },
                          {
                            'inline_data': {
                              'mime_type': 'image/jpeg',
                              'data': base64Image
                            }
                          }
                        ]
                      }
                    ],
                    'generation_config': {
                      'max_output_tokens': maxTokens,
                      'temperature': 0.4,
                      'top_p': 0.95,
                      'top_k': 40
                    },
                  }),
                ).timeout(const Duration(seconds: 30));
                
                if (fallbackResponse.statusCode == 200) {
                  final fallbackData = jsonDecode(fallbackResponse.body);
                  if (fallbackData.containsKey('candidates') && 
                      fallbackData['candidates'].isNotEmpty && 
                      fallbackData['candidates'][0].containsKey('content') &&
                      fallbackData['candidates'][0]['content'].containsKey('parts') &&
                      fallbackData['candidates'][0]['content']['parts'].isNotEmpty) {
                    
                    final description = fallbackData['candidates'][0]['content']['parts'][0]['text'];
                    
                    if (description != null && description.isNotEmpty) {
                      return {
                        'success': true,
                        'description': description,
                      };
                    }
                  }
                }
              }
              
              // If the fallback also fails, return an informative error
              return {
                'success': false,
                'error': 'API returned metadata only with no content',
                'details': 'The model may be unavailable or unauthorized',
              };
            }
            
            // If we reached here, the response format was unexpected
            if (kDebugMode) {
              print('Unexpected response format: ${response.body}');
            }
            
            throw Exception('Unexpected response format');
          } else {
            if (kDebugMode) {
              print('API Error: ${response.statusCode}, ${response.body}');
            }
            
            if (response.statusCode == 429 || response.statusCode >= 500) {
              // Rate limit or server error - retry with backoff
              retryCount++;
              if (retryCount <= maxRetries) {
                await Future.delayed(Duration(seconds: retryCount * 2));
                continue;
              }
            }
            
            return {
              'success': false,
              'error': 'API Error: ${response.statusCode}',
              'details': response.body,
            };
          }
        } catch (e) {
          retryCount++;
          if (retryCount <= maxRetries) {
            await Future.delayed(Duration(seconds: retryCount));
            continue;
          }
          
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
      
      // If we've exhausted retries, return error
      return {
        'success': false,
        'error': 'Maximum retries exceeded',
      };
    } catch (e) {
      if (kDebugMode) {
        print('Error in generateSceneDescription outer try/catch: $e');
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
      final apiKey = await getApiKey();
      
      // Compress image before sending
      final compressedImage = await _compressImageBasedOnNetworkQuality(imageFile);
      
      // Get language preference
      final prefs = await SharedPreferences.getInstance();
      String languageCode = prefs.getString('tts_language') ?? 'en-US';
      
      // Convert image to base64
      final bytes = await compressedImage.readAsBytes();
      final base64Image = base64Encode(bytes);
      
      if (kDebugMode) {
        print('Making question API request for language: $languageCode');
      }
      
      // Determine system prompt based on language preference
      String systemPrompt;
      if (languageCode == 'hi-IN') {
        systemPrompt = 'You are a helpful assistant for visually impaired users. Answer questions about the image clearly and concisely. For Hindi language users, respond in Hinglish (mix of Hindi and English) in your response. Do not translate technical terms to pure Hindi, keep them in English. Be conversational and natural. Do not use markdown formatting or asterisks for emphasis.';
      } else {
        systemPrompt = 'You are a helpful assistant for visually impaired users. Answer questions about the image clearly and concisely. Do not use markdown formatting or asterisks for emphasis.';
      }
      
      // Try with primary model first, then fallback
      final models = [_model, 'gemini-pro-vision'];
      
      for (int i = 0; i < models.length; i++) {
        final currentModel = models[i];
        if (i > 0 && kDebugMode) {
          print('Trying fallback model for question: $currentModel');
        }
        
        final response = await http.post(
          Uri.parse('$_baseUrl/models/$currentModel:generateContent?key=$apiKey'),
          headers: {
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'contents': [
              {
                'parts': [
                  {
                    'text': systemPrompt + "\n\nQuestion: " + question
                  },
                  {
                    'inline_data': {
                      'mime_type': 'image/jpeg',
                      'data': base64Image
                    }
                  }
                ]
              }
            ],
            'generation_config': {
              'max_output_tokens': 300,
              'temperature': 0.4,
              'top_p': 0.95,
              'top_k': 40
            },
          }),
        );
        
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          
          // Check for metadata-only response
          if (data.containsKey('usageMetadata') && data.containsKey('modelVersion') && 
              !data.containsKey('candidates')) {
            if (kDebugMode) {
              print('Received metadata-only response for question');
            }
            
            // If this is not the last model to try, continue to next model
            if (i < models.length - 1) {
              continue;
            }
            
            return {
              'success': false,
              'error': 'API returned metadata only with no content',
              'details': 'The model may be unavailable or unauthorized',
            };
          }
          
          // Check for normal response with candidates
          if (data.containsKey('candidates') && 
              data['candidates'].isNotEmpty && 
              data['candidates'][0].containsKey('content') &&
              data['candidates'][0]['content'].containsKey('parts') &&
              data['candidates'][0]['content']['parts'].isNotEmpty) {
            
            final answer = data['candidates'][0]['content']['parts'][0]['text'];
            
            if (answer != null && answer.isNotEmpty) {
              return {
                'success': true,
                'answer': _cleanupResponseText(answer),
              };
            }
          }
          
          // If we reach here, the response format was unexpected
          if (kDebugMode) {
            print('Unexpected response format for question: ${response.body}');
          }
          
          // Try the next model if available
          if (i < models.length - 1) {
            continue;
          }
        } else {
          // If this is not the last model to try, continue to next model
          if (i < models.length - 1) {
            continue;
          }
          
          return {
            'success': false,
            'error': 'API Error: ${response.statusCode}',
            'details': response.body,
          };
        }
      }
      
      // If we've tried all models and nothing worked
      return {
        'success': false,
        'error': 'Failed to get answer from any model',
        'details': 'All available models failed to generate a response',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Error answering question about image',
        'details': e.toString(),
      };
    }
  }
  
  // For streaming responses (low latency)
  Stream<String> streamImageAnalysis(File imageFile) async* {
    try {
      final apiKey = await getApiKey();
      
      // Compress image before sending
      final compressedImage = await _compressImageBasedOnNetworkQuality(imageFile);
      
      final bytes = await compressedImage.readAsBytes();
      final base64Image = base64Encode(bytes);
      
      final prefs = await SharedPreferences.getInstance();
      String languageCode = prefs.getString('tts_language') ?? 'en-US';
      
      String prompt;
      if (languageCode == 'hi-IN') {
        prompt = 'You are a helpful assistant for visually impaired users. Describe this image in Hinglish (mix of Hindi and English), focusing on important elements, text content, people, and potential hazards. Keep technical terms in English. Be concise.';
      } else {
        prompt = 'You are a helpful assistant for visually impaired users. Describe this image concisely, focusing on important elements, text content, people, and potential hazards.';
      }
      
      // First try with the primary model
      String model = _model;
      bool useFallback = false;
      
      for (int attempt = 0; attempt < 2; attempt++) {
        if (attempt == 1) {
          // Switch to fallback model on second attempt
          model = 'gemini-pro-vision';
          useFallback = true;
          if (kDebugMode) {
            print('Trying fallback model for streaming: $model');
          }
        }
        
        // For streaming, we need to use a different endpoint with stream=true
        final request = http.Request(
          'POST', 
          Uri.parse('$_baseUrl/models/$model:streamGenerateContent?key=$apiKey')
        );
        
        request.headers['Content-Type'] = 'application/json';
        request.body = jsonEncode({
          'contents': [
            {
              'parts': [
                {
                  'text': prompt
                },
                {
                  'inline_data': {
                    'mime_type': 'image/jpeg',
                    'data': base64Image
                  }
                }
              ]
            }
          ],
          'generation_config': {
            'max_output_tokens': 500,
            'temperature': 0.4,
            'top_p': 0.95,
            'top_k': 40
          },
        });
        
        final streamedResponse = await http.Client().send(request);
        
        if (streamedResponse.statusCode != 200) {
          if (attempt == 0) {
            // If first attempt fails, try the fallback model
            continue;
          }
          throw Exception('API Error: ${streamedResponse.statusCode}');
        }
        
        // Use a buffer to accumulate JSON data correctly
        String buffer = '';
        bool gotContent = false;
        
        // Parse the streamed response
        await for (var chunk in streamedResponse.stream.transform(utf8.decoder)) {
          if (kDebugMode) {
            print('Received chunk: ${chunk.length} characters');
          }
          
          // Add the new chunk to our buffer
          buffer += chunk;
          
          // Try to extract complete JSON objects from the buffer
          while (true) {
            // Look for a complete JSON object
            int openBrace = buffer.indexOf('{');
            if (openBrace == -1) {
              buffer = ''; // No JSON object started, clear buffer
              break;
            }
            
            // Find matching closing brace by counting braces
            int braceCount = 0;
            int closingIndex = -1;
            
            for (int i = openBrace; i < buffer.length; i++) {
              if (buffer[i] == '{') braceCount++;
              if (buffer[i] == '}') braceCount--;
              
              if (braceCount == 0) {
                closingIndex = i + 1;
                break;
              }
            }
            
            // If we didn't find a complete JSON object, wait for more data
            if (closingIndex == -1) break;
            
            // Extract the JSON object
            String jsonStr = buffer.substring(openBrace, closingIndex);
            buffer = buffer.substring(closingIndex); // Remove processed part
            
            // Try to parse the JSON
            try {
              final data = jsonDecode(jsonStr);
              
              // Check if we received a metadata-only response
              if (data.containsKey('usageMetadata') && data.containsKey('modelVersion') && 
                  !data.containsKey('candidates')) {
                if (kDebugMode) {
                  print('Received metadata-only response in stream');
                }
                
                // If it's the first attempt, break to try the fallback model
                if (attempt == 0) {
                  gotContent = false;
                  break;
                }
              }
              
              // Extract text from different possible response formats
              if (data.containsKey('candidates') && 
                  data['candidates'].isNotEmpty && 
                  data['candidates'][0].containsKey('content')) {
                
                // Handle different content formats
                var content = data['candidates'][0]['content'];
                
                if (content.containsKey('parts') && 
                    content['parts'].isNotEmpty && 
                    content['parts'][0].containsKey('text')) {
                  
                  final text = content['parts'][0]['text'];
                  if (text != null && text.isNotEmpty) {
                    gotContent = true;
                    yield text;
                  }
                }
              }
            } catch (e) {
              if (kDebugMode) {
                print('Error parsing JSON: $e');
              }
              // Continue to the next iteration even if parsing fails
            }
          }
          
          // If we didn't get any content and it's the first attempt, break to try fallback
          if (!gotContent && attempt == 0) {
            break;
          }
        }
        
        // If we got content, we're done
        if (gotContent) {
          break;
        }
      }
      
      // If we got here with useFallback=true but didn't yield any content,
      // we've tried both models and failed
      if (useFallback) {
        // Return a fallback response when streaming fails
        yield "I'm unable to analyze this image at the moment. Please try again with a clearer image or check your internet connection.";
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error in streamImageAnalysis: $e');
      }
      // Instead of yielding a fallback, throw an exception so the caller can handle it
      throw Exception('Failed to stream image analysis: $e');
    }
  }
  
  // Get recommended scanning interval based on recent performance and network quality
  Duration getRecommendedScanningInterval() {
    // Base interval on connection quality
    final baseInterval = _connectivityService.getRecommendedProcessingInterval();
    
    // Adjust based on recent response times
    Duration adjustedInterval;
    
    if (_lastResponseTimeMs > 5000) {
      // If responses are very slow, increase interval significantly
      adjustedInterval = baseInterval + const Duration(seconds: 3);
    } else if (_lastResponseTimeMs > 2000) {
      // If responses are somewhat slow, increase interval moderately
      adjustedInterval = baseInterval + const Duration(seconds: 1);
    } else if (_lastResponseTimeMs < 500) {
      // If responses are very fast, decrease interval slightly
      adjustedInterval = Duration(milliseconds: max(baseInterval.inMilliseconds - 500, 1000));
    } else {
      // Otherwise, use the base interval
      adjustedInterval = baseInterval;
    }
    
    // Enforce a minimum interval of 2.5 seconds to prevent camera issues
    final minimumSafeInterval = const Duration(milliseconds: 2500);
    return adjustedInterval.inMilliseconds < minimumSafeInterval.inMilliseconds 
        ? minimumSafeInterval 
        : adjustedInterval;
  }
  
  // Dispose of resources
  void dispose() {
    _connectivityService.dispose();
  }
} 