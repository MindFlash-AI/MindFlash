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
  static const Color background = Color(0xFFE2E4E9); // 🛡️ HCI: Soothing slate grey
}

final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.dark);

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      // 🛡️ HCI: Using a softer, cooler slate grey to dramatically reduce glare and eye strain
      scaffoldBackgroundColor: const Color(0xFFE2E4E9), 
      cardColor: Colors.white, // Crisp white reserved only for elevated components
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF8B4EFF),
        brightness: Brightness.light,
        surface: const Color(0xFFE2E4E9),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFE2E4E9),
        // 🛡️ HCI: Soft slate gray instead of harsh pure black
        foregroundColor: Color(0xFF1E293B), 
        elevation: 0,
      ),
      textTheme: const TextTheme(
        // 🛡️ HCI: Avoid pure #000000 on light backgrounds to prevent halation (eye strain).
        // Dark slate grays look much more premium and are gentler on the eyes.
        bodyLarge: TextStyle(color: Color(0xFF1E293B)), 
        bodyMedium: TextStyle(color: Color(0xFF475569)), 
        titleLarge: TextStyle(color: Color(0xFF0F172A)), 
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