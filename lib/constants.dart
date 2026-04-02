import 'package:flutter/material.dart';

class Constants {
  // 🛡️ WEB FIX: Must use 'const' to pick up values from build flags
  static const String revenueCatAppleApiKey = String.fromEnvironment('REVENUECAT_APPLE_KEY');
  static const String revenueCatGoogleApiKey = String.fromEnvironment('REVENUECAT_GOOGLE_KEY');
  
  static const String entitlementId = 'MindFlash: AI Flashcards Pro';
}

class AppColors {
  static const Color blueStart = Color(0xFF5B4FE6);
  static const Color pinkStart = Color(0xFFE940A3);
  static const Color background = Color(0xFFF8F9FA);
}

final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFFDF9FF),
      cardColor: Colors.white,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF8B4EFF),
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFFDF9FF),
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Colors.black87),
        bodyMedium: TextStyle(color: Colors.black87),
        titleLarge: TextStyle(color: Colors.black87),
      ),
      useMaterial3: true,
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF0B0714), 
      cardColor: const Color(0xFF1A1128), 
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF8B4EFF),
        brightness: Brightness.dark,
        surface: const Color(0xFF1A1128),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF0B0714),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      useMaterial3: true,
    );
  }
}