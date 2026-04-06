import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../widgets/web_navigation_bar.dart'; 
import '../widgets/web_footer.dart'; // 🛡️ Imported the global footer
import '../login/web_login_screen.dart';
import '../../dashboard/dashboard_screen.dart';
import '../../../widgets/web_pro_gate.dart';
import '../web_landing_screen.dart'; // 🛡️ Imported for HoverLift and HoverScale

class FeaturesScreen extends StatelessWidget {
  const FeaturesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 800;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SelectionArea(
        child: Container(
        width: double.infinity,
        height: double.infinity,
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
            // --- Premium Ambient Background Glows ---
            Positioned(
              top: -100,
              left: -100,
              child: Container(
                width: 600, height: 600,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFE841A1).withValues(alpha: isDark ? 0.1 : 0.03),
                  boxShadow: [BoxShadow(color: const Color(0xFFE841A1).withValues(alpha: isDark ? 0.1 : 0.03), blurRadius: 150)],
                ),
              ),
            ),
            Positioned(
              bottom: 100,
              right: -100,
              child: Container(
                width: 500, height: 500,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF8B4EFF).withValues(alpha: isDark ? 0.15 : 0.05),
                  boxShadow: [BoxShadow(color: const Color(0xFF8B4EFF).withValues(alpha: isDark ? 0.15 : 0.05), blurRadius: 150)],
                ),
              ),
            ),

            Positioned.fill(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    // --- Header Section ---
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1200),
                        child: Padding(
                          padding: EdgeInsets.only(
                            left: isMobile ? 32.0 : 64.0,
                            right: isMobile ? 32.0 : 64.0,
                            top: isMobile ? 140.0 : 180.0, 
                            bottom: 60.0,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF8B4EFF).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: const Color(0xFF8B4EFF).withValues(alpha: 0.3)),
                                ),
                                child: const Text(
                                  "THE MINDFLASH ARSENAL",
                                  style: TextStyle(color: Color(0xFF8B4EFF), fontWeight: FontWeight.bold, letterSpacing: 0.5),
                                ),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                "Study at the speed of thought.",
                                textAlign: TextAlign.center,
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
                                "Everything you need to master any topic, beautifully designed for web and mobile.",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: isMobile ? 18 : 20,
                                  height: 1.5,
                                  color: isDark ? Colors.white70 : Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    
                    // --- Expanded Feature Grid ---
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1200),
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: isMobile ? 32.0 : 64.0),
                          child: Wrap(
                            spacing: 32,
                            runSpacing: 32,
                            alignment: WrapAlignment.center,
                            children: [
                              HoverLift(child: _buildFeatureCard(context, isDark, "AI Generation", "Upload PDFs, text, or enter a prompt. Our Gemini-powered engine instantly extracts definitions, formulas, and concepts into comprehensive flashcard decks.", Icons.auto_awesome_rounded)),
                              HoverLift(child: _buildFeatureCard(context, isDark, "Spaced Repetition", "Stop wasting time reviewing things you already know. Our algorithm schedules reviews at the optimal cognitive interval, maximizing long-term retention.", Icons.sync_rounded)),
                              HoverLift(child: _buildFeatureCard(context, isDark, "AI Tutor Chat", "It's like having a professor in your pocket. Chat directly with our AI Tutor to get simplified explanations, analogies, and examples for any tricky flashcard.", Icons.chat_bubble_outline_rounded)),
                              HoverLift(child: _buildFeatureCard(context, isDark, "Interactive Study Pad", "A beautifully designed, distraction-free rich-text editor for your notes. Supports infinite canvas drawing, handwriting recognition, and seamless AI generation.", Icons.edit_note_rounded)),
                              HoverLift(child: _buildFeatureCard(context, isDark, "Cross-Platform Sync", "Your brain doesn't stop, and neither do we. Start studying on your phone during your commute, and finish building your deck on your desktop Web app.", Icons.devices_rounded)),
                              HoverLift(child: _buildFeatureCard(context, isDark, "Rich Formatting & Math", "Full support for bold text, italics, lists, code blocks, and LaTeX math equations. Make your flashcards look exactly the way you learn best.", Icons.format_paint_rounded)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 120),
                    
                    // --- Bottom CTA ---
                    _buildBottomCTA(context, isDark, isMobile),
                    const SizedBox(height: 60),

                    // --- Global Footer ---
                    const WebFooter(),
                  ],
                ),
              ),
            ),
            
            // --- Sticky Navbar ---
            Positioned(
              top: 0, left: 0, right: 0,
              child: WebNavBar(activePage: "Features", onActionTap: () => _launchWebApp(context)),
            ),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard(BuildContext context, bool isDark, String title, String description, IconData icon) {
    return Container(
      width: 340, // Slightly wider for better text flow
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF8B4EFF).withValues(alpha: isDark ? 0.2 : 0.1), 
                  const Color(0xFFE841A1).withValues(alpha: isDark ? 0.2 : 0.1)
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: const Color(0xFF8B4EFF), size: 32),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: TextStyle(
              fontSize: 16,
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
    if (FirebaseAuth.instance.currentUser != null) {
      Navigator.push(
        context, 
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const WebProGate(child: DashboardScreen()),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        )
      );
    } else {
      Navigator.push(context, MaterialPageRoute(builder: (context) => const WebLoginScreen()));
    }
  }
}