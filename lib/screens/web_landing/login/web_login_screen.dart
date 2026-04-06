import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../services/auth_service.dart';
import '../../../widgets/web_pro_gate.dart';
import '../../dashboard/dashboard_screen.dart';
import '../../../constants/constants.dart';
import '../../web_landing/web_landing_screen.dart';

class WebLoginScreen extends StatefulWidget {
  const WebLoginScreen({super.key});

  @override
  State<WebLoginScreen> createState() => _WebLoginScreenState();
}

class _WebLoginScreenState extends State<WebLoginScreen> with TickerProviderStateMixin {
  bool _isLoading = false;

  // 🛡️ Animation Controllers
  late AnimationController _entranceController;
  late AnimationController _floatController;

  @override
  void initState() {
    super.initState();
    
    // Staggered entrance animation for the form elements
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();

    // Gentle floating animation for the logo
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  void _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    
    final user = await AuthService().signInWithGoogle();
    
    if (mounted) {
      if (user != null) {
        // Success! Route them back to the WebLandingScreen
        context.go('/');
      } else {
        setState(() => _isLoading = false);
        // Show error snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Sign in failed. Please try again."),
            backgroundColor: Colors.redAccent.shade200,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  // 🛡️ Safe back navigation logic
  void _safeNavigateBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 800; // Breakpoint for split-screen

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Row(
        children: [
          // --- Left Side: Branding (Hidden on Mobile) ---
          if (!isMobile)
            Expanded(
              flex: 5,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.blueStart, AppColors.pinkStart],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(60.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Desktop Back Button
                      IconButton(
                        onPressed: _safeNavigateBack,
                        icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                        style: IconButton.styleFrom(backgroundColor: Colors.white.withValues(alpha: 0.2)),
                        tooltip: "Back to Website",
                      ),
                      
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 🛡️ Floating Animated Logo
                          AnimatedBuilder(
                            animation: _floatController,
                            builder: (context, child) {
                              final yOffset = sin(_floatController.value * 2 * pi) * 12;
                              return Transform.translate(
                                offset: Offset(0, yOffset),
                                child: child,
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(28),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 30,
                                    offset: const Offset(0, 15),
                                  )
                                ],
                              ),
                              child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 64),
                            ),
                          ),
                          const SizedBox(height: 48),
                          
                          _AnimatedSlideFade(
                            controller: _entranceController,
                            interval: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
                            child: const Text(
                              "Welcome back\nto MindFlash.",
                              style: TextStyle(
                                fontSize: 56,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                height: 1.1,
                                letterSpacing: -1,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          
                          _AnimatedSlideFade(
                            controller: _entranceController,
                            interval: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
                            child: Text(
                              "Sign in to access your AI flashcards, study decks, and progress across all your devices.",
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.white.withValues(alpha: 0.8),
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      _AnimatedSlideFade(
                        controller: _entranceController,
                        interval: const Interval(0.4, 1.0, curve: Curves.easeOutCubic),
                        child: Text(
                          "© ${DateTime.now().year} MindFlash. All rights reserved.",
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // --- Right Side: Login Form ---
          Expanded(
            flex: 4,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Container(
                  // 🛡️ Add a subtle elevated card background on Desktop
                  padding: EdgeInsets.all(isMobile ? 32.0 : 48.0),
                  decoration: isMobile ? null : BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                        blurRadius: 40,
                        offset: const Offset(0, 10),
                      )
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (isMobile) ...[
                        Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton(
                            onPressed: _safeNavigateBack,
                            icon: Icon(Icons.arrow_back_rounded, color: Theme.of(context).textTheme.bodyLarge?.color),
                          ),
                        ),
                        const SizedBox(height: 40),
                        
                        AnimatedBuilder(
                          animation: _floatController,
                          builder: (context, child) => Transform.translate(
                            offset: Offset(0, sin(_floatController.value * 2 * pi) * 8),
                            child: child,
                          ),
                          child: const Icon(Icons.bolt_rounded, color: Color(0xFF8B4EFF), size: 56),
                        ),
                        const SizedBox(height: 24),
                      ],
                      
                      _AnimatedSlideFade(
                        controller: _entranceController,
                        interval: const Interval(0.3, 0.8, curve: Curves.easeOutCubic),
                        child: Text(
                          "Sign In",
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      _AnimatedSlideFade(
                        controller: _entranceController,
                        interval: const Interval(0.4, 0.9, curve: Curves.easeOutCubic),
                        child: Text(
                          "Use your Google account to continue.",
                          style: TextStyle(
                            fontSize: 16,
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                        ),
                      ),
                      const SizedBox(height: 48),

                      // 🛡️ Premium Animated Google Sign In Button
                      _AnimatedSlideFade(
                        controller: _entranceController,
                        interval: const Interval(0.5, 1.0, curve: Curves.easeOutCubic),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          height: 60,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleGoogleSignIn,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                              foregroundColor: isDark ? Colors.white : Colors.black87,
                              disabledBackgroundColor: isDark ? Colors.white10 : Colors.grey.shade200,
                              disabledForegroundColor: isDark ? Colors.white54 : Colors.black38,
                              elevation: _isLoading ? 0 : (isDark ? 0 : 2),
                              shadowColor: Colors.black.withValues(alpha: 0.1),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                  color: isDark ? Colors.white12 : Colors.grey.shade300,
                                  width: 1,
                                ),
                              ),
                            ),
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              child: _isLoading
                                  ? Row(
                                      key: const ValueKey('loading'),
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 3,
                                            color: isDark ? Colors.white70 : const Color(0xFF8B4EFF),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        const Text(
                                          "Signing you in...",
                                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    )
                                  : Row(
                                      key: const ValueKey('idle'),
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.g_mobiledata_rounded, 
                                            size: 28, 
                                            color: isDark ? Colors.white : Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        const Text(
                                          "Continue with Google",
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 48),
                      _AnimatedSlideFade(
                        controller: _entranceController,
                        interval: const Interval(0.6, 1.0, curve: Curves.easeOutCubic),
                        child: Text(
                          "By continuing, you agree to our Terms of Service and Privacy Policy.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white38 : Colors.black38,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// 🛡️ Helper widget for clean, staggered entrance animations
class _AnimatedSlideFade extends StatelessWidget {
  final Widget child;
  final AnimationController controller;
  final Interval interval;

  const _AnimatedSlideFade({
    required this.child,
    required this.controller,
    required this.interval,
  });

  @override
  Widget build(BuildContext context) {
    final animation = CurvedAnimation(parent: controller, curve: interval);
    
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Opacity(
          opacity: animation.value,
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - animation.value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}