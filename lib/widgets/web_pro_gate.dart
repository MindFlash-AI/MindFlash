import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../services/pro_service.dart';
import '../services/auth_service.dart';
import '../screens/web_landing/web_landing_screen.dart'; // 🛡️ Changed import
import '../constants/constants.dart';

/// A wrapper widget that blocks non-Pro users from accessing the Web version of the app.
class WebProGate extends StatelessWidget {
  final Widget child;

  const WebProGate({super.key, required this.child});

  void _handleLogout(BuildContext context) async {
    HapticFeedback.lightImpact();
    await AuthService().signOut();
    if (context.mounted) {
      // 🛡️ When logging out on the web, route them back to the Landing Page
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const WebLandingScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. If the user is on iOS or Android, let them right through!
    if (!kIsWeb) return child;

    // 2. If they are on the web, listen to their Pro status
    return AnimatedBuilder(
      animation: ProService(),
      builder: (context, _) {
        // 3. If they are Pro, grant them access to the web app!
        if (ProService().isPro) return child;

        final isDark = Theme.of(context).brightness == Brightness.dark;

        // 4. If they are on Web and NOT Pro, show the beautiful lock screen
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: Stack(
            children: [
              // Aesthetic Background Glows
              Positioned(
                top: -100,
                right: -100,
                child: Container(
                  width: 400,
                  height: 400,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.pinkStart.withOpacity(isDark ? 0.1 : 0.05),
                    boxShadow: [BoxShadow(color: AppColors.pinkStart.withOpacity(isDark ? 0.2 : 0.1), blurRadius: 100)],
                  ),
                ),
              ),
              Positioned(
                bottom: -100,
                left: -100,
                child: Container(
                  width: 400,
                  height: 400,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.blueStart.withOpacity(isDark ? 0.1 : 0.05),
                    boxShadow: [BoxShadow(color: AppColors.blueStart.withOpacity(isDark ? 0.2 : 0.1), blurRadius: 100)],
                  ),
                ),
              ),
              
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(40.0),
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 500),
                    padding: const EdgeInsets.all(40),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor.withOpacity(isDark ? 0.7 : 1.0),
                      borderRadius: BorderRadius.circular(32),
                      border: isDark ? Border.all(color: Colors.white.withOpacity(0.05)) : null,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Lock / Laptop Icon
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [AppColors.pinkStart.withOpacity(0.2), AppColors.blueStart.withOpacity(0.2)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: const Icon(Icons.laptop_mac_rounded, size: 64, color: AppColors.pinkStart),
                        ),
                        const SizedBox(height: 32),
                        
                        Text(
                          "Desktop Access Locked",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        Text(
                          "MindFlash Web is an exclusive feature for Pro members. It allows you to study and create flashcards with a full keyboard and monitor.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: isDark ? Colors.white70 : Colors.grey.shade700,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 32),
                        
                        // Mobile Instructions Box
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.black26 : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.phone_iphone_rounded, color: AppColors.blueStart, size: 32),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  "Open MindFlash on your iOS or Android device to study for free, or to upgrade to Pro to unlock this web version.",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isDark ? Colors.white60 : Colors.black87,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 32),
                        
                        TextButton.icon(
                          onPressed: () => _handleLogout(context),
                          icon: const Icon(Icons.logout_rounded, color: Colors.grey),
                          label: const Text("Sign Out", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}