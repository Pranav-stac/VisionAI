import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData getDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF090909),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF6366F1),    // Electric indigo
        secondary: Color(0xFFEC4899),   // Vibrant pink
        tertiary: Color(0xFF9333EA),    // Purple
        surface: Color(0xFF1E1E2D),     // Dark blue-grey
        background: Color(0xFF121212),   // Dark charcoal
        error: Color(0xFFEF4444),       // Error red
        onPrimary: Color(0xFFE5E7EB),   // Light grey
        onSecondary: Color(0xFFE5E7EB), // Light grey
        onSurface: Color(0xFFE5E7EB),   // Light grey
        onBackground: Color(0xFFE5E7EB), // Light grey
        onError: Color(0xFFE5E7EB),     // Light grey
      ),
      cardTheme: CardTheme(
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: const Color(0xFF1E1E2D).withOpacity(0.85),
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(
          color: Color(0xFFE5E7EB),
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
        titleMedium: TextStyle(
          color: Color(0xFFE5E7EB),
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(
          color: Color(0xFFE5E7EB),
          fontSize: 16,
        ),
        bodyMedium: TextStyle(
          color: Color(0xFF9CA3AF),
          fontSize: 14,
        ),
        bodySmall: TextStyle(
          color: Color(0xFF9CA3AF),
          fontSize: 12,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1E1E2D).withOpacity(0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFF6366F1),
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: const Color(0xFFE5E7EB).withOpacity(0.1),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFF6366F1),
            width: 2,
          ),
        ),
        labelStyle: TextStyle(
          color: const Color(0xFFE5E7EB).withOpacity(0.8),
        ),
        hintStyle: TextStyle(
          color: const Color(0xFF9CA3AF).withOpacity(0.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6366F1),
          foregroundColor: const Color(0xFFE5E7EB),
          elevation: 4,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFF1E1E2D),
        selectedColor: const Color(0xFF6366F1).withOpacity(0.2),
        labelStyle: const TextStyle(color: Color(0xFFE5E7EB)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: const Color(0xFFE5E7EB).withOpacity(0.1),
          ),
        ),
      ),
      tabBarTheme: TabBarTheme(
        labelColor: const Color(0xFF6366F1),
        unselectedLabelColor: const Color(0xFF9CA3AF),
        indicator: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: const Color(0xFF6366F1),
              width: 2,
            ),
          ),
        ),
      ),
    );
  }
} 