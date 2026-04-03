import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../widgets/web_navigation_bar.dart'; 
import '../widgets/web_footer.dart'; // 🛡️ Imported the global footer
import '../login/web_login_screen.dart';
import '../../dashboard/dashboard_screen.dart';
import '../../../widgets/web_pro_gate.dart';
import '../web_landing_screen.dart'; // 🛡️ Imported for HoverLift and HoverScale

class HowItWorksScreen extends StatelessWidget {
  const HowItWorksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 800;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Container(
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
                                  color: const Color(0xFF8B4EFF).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: const Color(0xFF8B4EFF).withOpacity(0.3)),
                                ),
                                child: const Text(
                                  "SIMPLE & FAST",
                                  style: TextStyle(color: Color(0xFF8B4EFF), fontWeight: FontWeight.bold, letterSpacing: 0.5),
                                ),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                "How It Works",
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
                                "Go from raw notes to mastering the subject in three easy steps.",
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
                    
                    // --- 3-Step Process Grid ---
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
                              HoverLift(child: _buildStepCard(context, isDark, "1", "Upload your material", "Paste your text, upload a PDF, or write a prompt. MindFlash handles any format seamlessly.", Icons.upload_file_rounded)),
                              HoverLift(child: _buildStepCard(context, isDark, "2", "AI generates your deck", "Our powerful engine instantly extracts key concepts and creates high-quality question-answer pairs.", Icons.memory_rounded)),
                              HoverLift(child: _buildStepCard(context, isDark, "3", "Master the topic", "Use our smart spaced repetition interface to study efficiently, track progress, and ace your exams.", Icons.school_rounded)),
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
              child: WebNavBar(onActionTap: () => _launchWebApp(context)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepCard(BuildContext context, bool isDark, String stepNum, String title, String description, IconData icon) {
    return Container(
      width: 340,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF8B4EFF), Color(0xFFE841A1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF8B4EFF).withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                )
              ],
            ),
            child: Center(
              child: Text(
                stepNum,
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              height: 1.5,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
          const SizedBox(height: 32),
          Icon(icon, size: 48, color: isDark ? Colors.white24 : Colors.black12),
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
                  color: const Color(0xFF8B4EFF).withOpacity(0.3),
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
                    color: Colors.white.withOpacity(0.9),
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
                          color: Colors.black.withOpacity(0.2),
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