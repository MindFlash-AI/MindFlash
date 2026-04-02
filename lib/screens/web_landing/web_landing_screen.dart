import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart'; 
import 'login/web_login_screen.dart'; 
import '../dashboard/dashboard_screen.dart';
import '../../widgets/web_pro_gate.dart'; 
import 'widgets/web_navigation_bar.dart'; 
import '../../constants.dart'; 

class WebLandingScreen extends StatelessWidget {
  const WebLandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 800; // Breakpoint for mobile vs desktop layout

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [const Color(0xFF0B0714), const Color(0xFF1A1128)]
                : [const Color(0xFFFDF9FF), const Color(0xFFF3E8FF)],
          ),
        ),
        // 🛡️ HCI FIX: Switched from Column to Stack for Sticky Navigation
        child: Stack(
          children: [
            // --- Main Content (Scrollable) ---
            Positioned.fill(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: Padding(
                      padding: EdgeInsets.only(
                        left: isMobile ? 32.0 : 64.0,
                        right: isMobile ? 32.0 : 64.0,
                        // Add top padding so the hero content isn't hidden under the floating navbar initially
                        top: isMobile ? 120.0 : 160.0, 
                        bottom: isMobile ? 40.0 : 80.0,
                      ),
                      child: isMobile
                          ? _buildMobileLayout(context, isDark)
                          : _buildDesktopLayout(context, isDark),
                    ),
                  ),
                ),
              ),
            ),

            // --- Sticky Top Navigation Bar ---
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: WebNavBar(
                onActionTap: () {
                  final user = FirebaseAuth.instance.currentUser;
                  if (user != null) {
                    _launchWebApp(context); // Already logged in, go to Dashboard
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const WebLoginScreen()),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Left Column: Text & CTA
        Expanded(
          flex: 5,
          child: _buildHeroContent(context, isDark, isMobile: false),
        ),
        const SizedBox(width: 60),
        // Right Column: Illustration / App Mockup
        Expanded(
          flex: 4,
          child: _buildHeroImage(context, isDark),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildHeroContent(context, isDark, isMobile: true),
        const SizedBox(height: 60),
        _buildHeroImage(context, isDark),
      ],
    );
  }

  Widget _buildHeroContent(BuildContext context, bool isDark, {required bool isMobile}) {
    return Column(
      crossAxisAlignment: isMobile ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF8B4EFF).withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF8B4EFF).withOpacity(0.3)),
          ),
          child: const Text(
            "✨ Now available on the Web for Pro Users",
            style: TextStyle(color: Color(0xFF8B4EFF), fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          "Master any subject\nwith AI Flashcards.",
          textAlign: isMobile ? TextAlign.center : TextAlign.left,
          style: TextStyle(
            fontSize: isMobile ? 42 : 64,
            fontWeight: FontWeight.w900,
            height: 1.1,
            letterSpacing: -1.5,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          "Upload your notes and let MindFlash generate perfect study decks in seconds. Study smarter with active recall and spaced repetition.",
          textAlign: isMobile ? TextAlign.center : TextAlign.left,
          style: TextStyle(
            fontSize: isMobile ? 18 : 20,
            height: 1.5,
            color: isDark ? Colors.white70 : Colors.black54,
          ),
        ),
        const SizedBox(height: 40),
        
        // --- Main CTA Button ---
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () => _launchWebApp(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF8B4EFF), Color(0xFFE841A1)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF8B4EFF).withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Launch Web App",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 12),
                  Icon(Icons.arrow_forward_rounded, color: Colors.white),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeroImage(BuildContext context, bool isDark) {
    return Container(
      height: 500,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 40,
            left: 40,
            right: 40,
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF8B4EFF), Color(0xFFE841A1)],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
          Positioned(
            bottom: -20,
            left: 60,
            right: 60,
            child: Container(
              height: 300,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2A1B3D) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, -10),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(Icons.style_rounded, size: 80, color: Color(0xFF8B4EFF)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _launchWebApp(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      showDialog(
        context: context,
        builder: (context) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return AlertDialog(
            backgroundColor: Theme.of(context).cardColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Row(
              children: [
                const Icon(Icons.lock_person_rounded, color: Color(0xFF8B4EFF)),
                const SizedBox(width: 12),
                Text(
                  "Authentication Required",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
              ],
            ),
            content: Text(
              "You need to sign in or create an account before launching the MindFlash Web App.",
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black87,
                fontSize: 16,
                height: 1.5,
              ),
            ),
            actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); 
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const WebLoginScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B4EFF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text("Sign In", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      );
      return; 
    }

    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const WebProGate(child: DashboardScreen()),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }
}