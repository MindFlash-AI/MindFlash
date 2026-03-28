import 'package:flutter/material.dart';

class AppColors {
  static const Color blueStart = Color(0xFF5B4FE6);
  static const Color pinkStart = Color(0xFFE940A3);
  static const Color background = Color(0xFFF8F9FA);
}

// Global Theme Notifier for Dark Mode Toggle
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
      scaffoldBackgroundColor: const Color(0xFF0B0714), // Deep Space Violet
      cardColor: const Color(0xFF1A1128), // Dark card color
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
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Colors.white),
        bodyMedium: TextStyle(color: Colors.white70),
        titleLarge: TextStyle(color: Colors.white),
      ),
      useMaterial3: true,
    );
  }
}