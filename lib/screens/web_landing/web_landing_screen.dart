import 'dart:ui'; // 🛡️ Added for ImageFilter (Glassmorphism & Glows)
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:firebase_auth/firebase_auth.dart'; 
import 'dart:math' as math;

import 'login/web_login_screen.dart'; 
import '../dashboard/dashboard_screen.dart';
import '../../widgets/web_pro_gate.dart'; 
import 'widgets/web_navigation_bar.dart'; 
import 'widgets/web_footer.dart'; 
import '../../constants/constants.dart'; 

class WebLandingScreen extends StatelessWidget {
  const WebLandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 800; 

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
        child: Stack(
          children: [
            // --- Main Content (Scrollable) ---
            Positioned.fill(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    _buildHeroSection(context, isDark, isMobile),
                    const SizedBox(height: 80),
                    
                    _buildStatsSection(context, isDark, isMobile),
                    const SizedBox(height: 120),
                    
                    _buildFeaturesSection(context, isDark, isMobile),
                    const SizedBox(height: 120),
                    
                    _buildBottomCTA(context, isDark, isMobile),
                    const SizedBox(height: 60),
                    
                    const WebFooter(), 
                  ],
                ),
              ),
            ),

            // --- Sticky Top Navigation Bar ---
            Positioned(
              top: 0, left: 0, right: 0,
              child: WebNavBar(
                onActionTap: () {
                  final user = FirebaseAuth.instance.currentUser;
                  if (user != null) {
                    _launchWebApp(context); 
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

  // ===========================================================================
  // SECTION 1: HERO
  // ===========================================================================
  Widget _buildHeroSection(BuildContext context, bool isDark, bool isMobile) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: Padding(
          padding: EdgeInsets.only(
            left: isMobile ? 32.0 : 64.0,
            right: isMobile ? 32.0 : 64.0,
            top: isMobile ? 140.0 : 180.0, 
            bottom: 40.0,
          ),
          child: isMobile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildHeroContent(context, isDark, isMobile: true),
                    const SizedBox(height: 60),
                    HeroInteractiveWrapper(child: _buildHeroImage(context, isDark)),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(flex: 5, child: _buildHeroContent(context, isDark, isMobile: false)),
                    const SizedBox(width: 60),
                    Expanded(flex: 5, child: HeroInteractiveWrapper(child: _buildHeroImage(context, isDark))),
                  ],
                ),
        ),
      ),
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
            color: const Color(0xFF8B4EFF).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF8B4EFF).withValues(alpha: 0.3)),
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
        
        HoverScale(
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
                  color: const Color(0xFF8B4EFF).withValues(alpha: 0.4),
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
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(width: 12),
                Icon(Icons.arrow_forward_rounded, color: Colors.white),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // 🛡️ REBUILT: Premium SaaS App Mockup
  Widget _buildHeroImage(BuildContext context, bool isDark) {
    return Container(
      height: 520,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1437) : Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B4EFF).withValues(alpha: isDark ? 0.3 : 0.15),
            blurRadius: 80,
            offset: const Offset(0, 30),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Stack(
          children: [
            // --- Ambient Background Glows ---
            Positioned(
              top: -50,
              right: -50,
              child: Container(
                width: 250, height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF8B4EFF).withValues(alpha: 0.4),
                ),
                child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80), child: Container()),
              ),
            ),
            Positioned(
              bottom: -50,
              left: -50,
              child: Container(
                width: 250, height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFE841A1).withValues(alpha: 0.3),
                ),
                child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80), child: Container()),
              ),
            ),

            // --- App Header (Mac Window Style) ---
            Positioned(
              top: 0, left: 0, right: 0,
              child: Container(
                height: 60,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02),
                  border: Border(bottom: BorderSide(color: isDark ? Colors.white12 : Colors.black12)),
                ),
                child: Row(
                  children: [
                    _buildWindowDot(Colors.redAccent),
                    const SizedBox(width: 8),
                    _buildWindowDot(Colors.orangeAccent),
                    const SizedBox(width: 8),
                    _buildWindowDot(Colors.greenAccent),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text("MindFlash Pro", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.black54)),
                    )
                  ],
                ),
              ),
            ),

            // --- Floating Flashcard Mockup ---
            Center(
              child: Transform.rotate(
                angle: -0.05,
                child: Container(
                  width: 320,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2A1B3D) : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFF8B4EFF).withValues(alpha: 0.5), width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 30,
                        offset: const Offset(0, 15),
                      )
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF8B4EFF).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text("Biology 101", style: TextStyle(color: Color(0xFF8B4EFF), fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                          Icon(Icons.volume_up_rounded, color: isDark ? Colors.white38 : Colors.black26, size: 20),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text("What is the powerhouse of the cell?", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color, height: 1.3)),
                      const SizedBox(height: 24),
                      Divider(color: isDark ? Colors.white12 : Colors.black12),
                      const SizedBox(height: 24),
                      const Text("Mitochondria", style: TextStyle(fontSize: 20, color: Color(0xFFE841A1), fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ),

            // --- Floating AI Badge ---
            Positioned(
              top: 100,
              right: 20,
              child: Transform.rotate(
                angle: 0.1,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2A1B3D) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.05)),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 20, offset: const Offset(0, 10))],
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.auto_awesome_rounded, color: Color(0xFFE841A1), size: 20),
                      SizedBox(width: 8),
                      Text("AI Generated", style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ),

            // --- Floating Mastery Badge ---
            Positioned(
              bottom: 80,
              left: 20,
              child: Transform.rotate(
                angle: -0.12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF8B4EFF), Color(0xFF5B4FE6)]),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: const Color(0xFF8B4EFF).withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 10))],
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text("Mastered", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWindowDot(Color color) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  // ===========================================================================
  // SECTION 2: STATS / SOCIAL PROOF
  // ===========================================================================
  Widget _buildStatsSection(BuildContext context, bool isDark, bool isMobile) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.02) : Colors.black.withValues(alpha: 0.02),
        border: Border.symmetric(
          horizontal: BorderSide(color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.05)),
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Wrap(
            alignment: WrapAlignment.spaceEvenly,
            spacing: isMobile ? 40 : 80,
            runSpacing: 40,
            children: [
              _buildStatItem(context, isDark, "10K+", "Active Students"),
              _buildStatItem(context, isDark, "1M+", "Cards Generated"),
              _buildStatItem(context, isDark, "4.9/5", "App Store Rating"),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, bool isDark, String value, String label) {
    return HoverLift(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w900,
              color: Theme.of(context).textTheme.bodyLarge?.color,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white54 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // SECTION 3: FEATURES OVERVIEW
  // ===========================================================================
  Widget _buildFeaturesSection(BuildContext context, bool isDark, bool isMobile) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: isMobile ? 32.0 : 64.0),
          child: Column(
            children: [
              Text(
                "Why choose MindFlash?",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isMobile ? 32 : 48,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "Everything you need to learn faster and retain information longer.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
              const SizedBox(height: 60),
              Wrap(
                spacing: 32,
                runSpacing: 32,
                alignment: WrapAlignment.center,
                children: [
                  HoverLift(child: _buildFeatureCard(context, isDark, "AI Generation", "Paste your notes or lectures and our AI will instantly extract key concepts into question-answer pairs.", Icons.auto_awesome_rounded)),
                  HoverLift(child: _buildFeatureCard(context, isDark, "Spaced Repetition", "Our smart algorithm perfectly times your reviews so you study exactly what you are about to forget.", Icons.sync_rounded)),
                  HoverLift(child: _buildFeatureCard(context, isDark, "Study Pad", "A beautifully designed WYSIWYG rich-text editor for you to organize, highlight, and format your thoughts.", Icons.edit_note_rounded)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard(BuildContext context, bool isDark, String title, String description, IconData icon) {
    return Container(
      width: 320,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF8B4EFF).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF8B4EFF), size: 28),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: TextStyle(
              fontSize: 15,
              height: 1.5,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // SECTION 4: BOTTOM CTA
  // ===========================================================================
  Widget _buildBottomCTA(BuildContext context, bool isDark, bool isMobile) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1000),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: isMobile ? 32.0 : 64.0),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(isMobile ? 40 : 60),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF8B4EFF), Color(0xFFE841A1)],
              ),
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF8B4EFF).withValues(alpha: 0.3),
                  blurRadius: 40,
                  offset: const Offset(0, 20),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  "Ready to ace your next exam?",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isMobile ? 32 : 48,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  "Join thousands of students learning faster with MindFlash.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isMobile ? 16 : 20,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 40),
                HoverScale(
                  onTap: () => _launchWebApp(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Text(
                      "Get Started for Free",
                      style: TextStyle(color: Color(0xFF8B4EFF), fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
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
              style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 16, height: 1.5),
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
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const WebLoginScreen()));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B4EFF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

// =============================================================================
// 🛡️ CUSTOM INTERACTIVE WIDGETS (Animations & Gestures)
// =============================================================================

/// 1. HoverLift: Smoothly floats upward and drops a deeper shadow on mouse hover.
class HoverLift extends StatefulWidget {
  final Widget child;
  const HoverLift({super.key, required this.child});

  @override
  State<HoverLift> createState() => _HoverLiftState();
}

class _HoverLiftState extends State<HoverLift> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.basic, 
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        transform: Matrix4.identity()..translate(0.0, _isHovered ? -12.0 : 0.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: _isHovered
              ? [
                  BoxShadow(
                    color: const Color(0xFF8B4EFF).withValues(alpha: isDark ? 0.3 : 0.2),
                    blurRadius: 30,
                    offset: const Offset(0, 15),
                  )
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  )
                ],
        ),
        child: widget.child,
      ),
    );
  }
}

/// 2. HoverScale: Smoothly scales up on hover, shrinks slightly when tapped.
class HoverScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scaleFactor;

  const HoverScale({super.key, required this.child, this.onTap, this.scaleFactor = 1.03});

  @override
  State<HoverScale> createState() => _HoverScaleState();
}

class _HoverScaleState extends State<HoverScale> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final scale = _isPressed ? 0.96 : (_isHovered ? widget.scaleFactor : 1.0);
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: widget.onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          if (widget.onTap != null) widget.onTap!();
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedScale(
          scale: scale,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          child: widget.child,
        ),
      ),
    );
  }
}

/// 3. HeroInteractiveWrapper: Combines a constant floating animation with 3D Mouse Parallax tilt.
class HeroInteractiveWrapper extends StatefulWidget {
  final Widget child;
  const HeroInteractiveWrapper({super.key, required this.child});

  @override
  State<HeroInteractiveWrapper> createState() => _HeroInteractiveWrapperState();
}

class _HeroInteractiveWrapperState extends State<HeroInteractiveWrapper> with SingleTickerProviderStateMixin {
  late final AnimationController _floatController;
  double _tiltX = 0.0;
  double _tiltY = 0.0;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(vsync: this, duration: const Duration(seconds: 4))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  void _onHover(PointerHoverEvent event) {
    if (!kIsWeb) return; 
    final size = context.size;
    if (size == null) return;
    
    final dx = (event.localPosition.dx / size.width) * 2 - 1; 
    final dy = (event.localPosition.dy / size.height) * 2 - 1; 
    
    setState(() {
      _tiltY = dx * 0.08;  
      _tiltX = -dy * 0.08; 
    });
  }

  void _onExit(PointerExitEvent event) {
    setState(() {
      _tiltX = 0.0;
      _tiltY = 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onHover: _onHover,
      onExit: _onExit,
      child: AnimatedBuilder(
        animation: _floatController,
        builder: (context, child) {
          final floatDy = math.sin(_floatController.value * math.pi) * 12.0;
          
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300), 
            curve: Curves.easeOutCubic,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001) 
              ..translate(0.0, floatDy, 0.0)
              ..rotateX(_tiltX)
              ..rotateY(_tiltY),
            alignment: FractionalOffset.center,
            child: child,
          );
        },
        child: widget.child,
      ),
    );
  }
}