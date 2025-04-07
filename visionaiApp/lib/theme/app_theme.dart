import 'package:flutter/material.dart';

// Light theme color scheme
final lightColorScheme = ColorScheme.fromSeed(
  seedColor: const Color(0xFF6750A4),
  brightness: Brightness.light,
  primary: const Color(0xFF6750A4),
  onPrimary: Colors.white,
  primaryContainer: const Color(0xFFEADDFF),
  onPrimaryContainer: const Color(0xFF21005E),
  secondary: const Color(0xFF625B71),
  onSecondary: Colors.white,
  secondaryContainer: const Color(0xFFE8DEF8),
  onSecondaryContainer: const Color(0xFF1E192B),
  tertiary: const Color(0xFF7D5260),
  onTertiary: Colors.white,
  tertiaryContainer: const Color(0xFFFFD8E4),
  onTertiaryContainer: const Color(0xFF370B1E),
  error: const Color(0xFFBA1A1A),
  onError: Colors.white,
  errorContainer: const Color(0xFFFFDAD6),
  onErrorContainer: const Color(0xFF410002),
  background: const Color(0xFFF8F9FA),
  onBackground: const Color(0xFF1C1B1F),
  surface: const Color(0xFFFFFBFE),
  onSurface: const Color(0xFF1C1B1F),
  surfaceVariant: const Color(0xFFE7E0EC),
  onSurfaceVariant: const Color(0xFF49454F),
  outline: const Color(0xFF79747E),
  shadow: const Color(0xFF000000),
);

// Dark theme color scheme
final darkColorScheme = ColorScheme.fromSeed(
  seedColor: const Color(0xFF6750A4),
  brightness: Brightness.dark,
  primary: const Color(0xFFD0BCFF),
  onPrimary: const Color(0xFF381E72),
  primaryContainer: const Color(0xFF4F378B),
  onPrimaryContainer: const Color(0xFFEADDFF),
  secondary: const Color(0xFFCCC2DC),
  onSecondary: const Color(0xFF332D41),
  secondaryContainer: const Color(0xFF4A4458),
  onSecondaryContainer: const Color(0xFFE8DEF8),
  tertiary: const Color(0xFFEFB8C8),
  onTertiary: const Color(0xFF492532),
  tertiaryContainer: const Color(0xFF633B48),
  onTertiaryContainer: const Color(0xFFFFD8E4),
  error: const Color(0xFFFFB4AB),
  onError: const Color(0xFF690005),
  errorContainer: const Color(0xFF93000A),
  onErrorContainer: const Color(0xFFFFDAD6),
  background: const Color(0xFF121212),
  onBackground: const Color(0xFFE6E1E5),
  surface: const Color(0xFF1C1B1F),
  onSurface: const Color(0xFFE6E1E5),
  surfaceVariant: const Color(0xFF49454F),
  onSurfaceVariant: const Color(0xFFCAC4D0),
  outline: const Color(0xFF938F99),
  shadow: const Color(0xFF000000),
);

// Text styles
const TextStyle headlineLarge = TextStyle(
  fontSize: 32,
  fontWeight: FontWeight.bold,
  letterSpacing: -0.5,
);

const TextStyle headlineMedium = TextStyle(
  fontSize: 28,
  fontWeight: FontWeight.bold,
  letterSpacing: -0.5,
);

const TextStyle headlineSmall = TextStyle(
  fontSize: 24,
  fontWeight: FontWeight.w600,
  letterSpacing: -0.5,
);

const TextStyle titleLarge = TextStyle(
  fontSize: 22,
  fontWeight: FontWeight.w600,
);

const TextStyle titleMedium = TextStyle(
  fontSize: 18,
  fontWeight: FontWeight.w600,
);

const TextStyle titleSmall = TextStyle(
  fontSize: 16,
  fontWeight: FontWeight.w600,
);

const TextStyle bodyLarge = TextStyle(
  fontSize: 16,
  fontWeight: FontWeight.normal,
);

const TextStyle bodyMedium = TextStyle(
  fontSize: 14,
  fontWeight: FontWeight.normal,
);

const TextStyle bodySmall = TextStyle(
  fontSize: 12,
  fontWeight: FontWeight.normal,
);

// Button styles
final ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
  backgroundColor: lightColorScheme.primary,
  foregroundColor: lightColorScheme.onPrimary,
  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
  ),
);

final ButtonStyle secondaryButtonStyle = ElevatedButton.styleFrom(
  backgroundColor: lightColorScheme.secondaryContainer,
  foregroundColor: lightColorScheme.onSecondaryContainer,
  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
  ),
);

// Card styles
final cardDecoration = BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(16),
  boxShadow: [
    BoxShadow(
      color: Colors.black.withOpacity(0.05),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ],
);

final darkCardDecoration = BoxDecoration(
  color: const Color(0xFF2D2D2D),
  borderRadius: BorderRadius.circular(16),
  boxShadow: [
    BoxShadow(
      color: Colors.black.withOpacity(0.2),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ],
); 