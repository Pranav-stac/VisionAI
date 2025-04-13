import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider with ChangeNotifier {
  // Default language is English
  String _languageCode = 'en';
  
  String get languageCode => _languageCode;
  
  // For backward compatibility
  Locale get locale => Locale(_languageCode, '');

  // Language names
  final Map<String, String> _languages = {
    'en': 'English',
    'hi': 'हिंदी',
    'mr': 'मराठी',
  };

  Map<String, String> get languages => _languages;

  LanguageProvider() {
    _loadSavedLanguage();
  }

  // Load the saved language from SharedPreferences
  Future<void> _loadSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString('languageCode') ?? 'en';
    setLanguage(languageCode);
  }

  // Set the app's language by language code
  Future<void> setLanguage(String languageCode) async {
    if (!_languages.containsKey(languageCode)) return;
    
    _languageCode = languageCode;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('languageCode', languageCode);
    
    notifyListeners();
  }

  // Legacy method for compatibility
  Future<void> setLocale(Locale locale) async {
    await setLanguage(locale.languageCode);
  }

  // Get the current language name
  String get currentLanguageName {
    return _languages[_languageCode] ?? 'English';
  }
} 