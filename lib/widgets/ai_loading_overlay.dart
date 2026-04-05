import 'dart:ui';
import 'package:flutter/material.dart';

class AILoadingOverlay {
  static void show(BuildContext context, {required String title, required String subtitle, Color indicatorColor = const Color(0xFF8B4EFF)}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      routeSettings: const RouteSettings(name: 'loading_overlay'),
      builder: (ctx) => PopScope(
        canPop: false,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
            child: Container(
              color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.85),
              width: double.infinity,
              height: double.infinity,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 60,
                    height: 60,
                    child: CircularProgressIndicator(color: indicatorColor, strokeWidth: 4),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    title,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Theme.of(context).textTheme.bodyLarge?.color, letterSpacing: -0.5),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15, color: isDark ? Colors.white70 : Colors.grey.shade700, height: 1.4, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static void close(BuildContext context) {
    bool foundOverlay = false;
    Navigator.of(context).popUntil((route) {
      if (route.settings.name == 'loading_overlay') {
        foundOverlay = true;
        return true;
      }
      if (route.isFirst) return true;
      return false;
    });
    if (foundOverlay) Navigator.of(context).pop();
  }
}