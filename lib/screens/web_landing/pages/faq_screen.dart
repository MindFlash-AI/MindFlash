import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

import '../widgets/web_navigation_bar.dart'; 
import '../widgets/web_footer.dart'; // 🛡️ Imported the global footer
import '../login/web_login_screen.dart';
import '../../dashboard/dashboard_screen.dart';
import '../../../widgets/web_pro_gate.dart';
import '../web_landing_screen.dart'; // 🛡️ Imported for HoverScale

class FAQScreen extends StatelessWidget {
  const FAQScreen({super.key});

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
              top: 100,
              right: -100,
              child: Container(
                width: 600, height: 600,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF8B4EFF).withValues(alpha: isDark ? 0.15 : 0.05),
                  boxShadow: [BoxShadow(color: const Color(0xFF8B4EFF).withValues(alpha: isDark ? 0.15 : 0.05), blurRadius: 150)],
                ),
              ),
            ),
            Positioned(
              bottom: -100,
              left: -100,
              child: Container(
                width: 500, height: 500,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFE841A1).withValues(alpha: isDark ? 0.1 : 0.03),
                  boxShadow: [BoxShadow(color: const Color(0xFFE841A1).withValues(alpha: isDark ? 0.1 : 0.03), blurRadius: 150)],
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
                        constraints: const BoxConstraints(maxWidth: 800),
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
                                  "SUPPORT",
                                  style: TextStyle(color: Color(0xFF8B4EFF), fontWeight: FontWeight.bold, letterSpacing: 0.5),
                                ),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                "Frequently Asked Questions",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: isMobile ? 42 : 56,
                                  fontWeight: FontWeight.w900,
                                  height: 1.1,
                                  letterSpacing: -1.5,
                                  color: Theme.of(context).textTheme.bodyLarge?.color,
                                ),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                "Everything you need to know about MindFlash and how it works.",
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
                    
                    // --- Interactive FAQ Accordion List ---
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 800),
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: isMobile ? 32.0 : 64.0),
                          child: Column(
                            children: [
                              _AnimatedFAQItem(
                                isDark: isDark, 
                                question: "How does AI Energy reset?", 
                                answer: "Energy powers our AI engine. Free users receive 15 daily energy credits, and Pro users receive 750 monthly credits. Generating a deck costs 3 energy, while chatting costs 1. Your energy resets at midnight UTC for daily plans, and at the start of each month UTC for monthly plans. If you run out, you can always watch a quick ad (mobile) or top-up (web) to get more!"
                              ),
                              const SizedBox(height: 20),
                              _AnimatedFAQItem(
                                isDark: isDark, 
                                question: "What is the difference between Free and Pro?", 
                                answer: "MindFlash Pro completely removes all advertisements, provides a massive allowance of 750 AI energy credits per month, and unlocks this Desktop Web version for heavy-duty study sessions. If you ever run out, you can instantly top-up your credits! It costs just \$1.00/month!"
                              ),
                              const SizedBox(height: 20),
                              _AnimatedFAQItem(
                                isDark: isDark, 
                                question: "Can I import my own notes or lectures?", 
                                answer: "Yes! You can paste raw text, write a custom prompt, or upload PDF, TXT, and Image (OCR) files directly into MindFlash. Our AI will automatically scan your documents and extract the key concepts."
                              ),
                              const SizedBox(height: 20),
                              _AnimatedFAQItem(
                                isDark: isDark, 
                                question: "Is the AI Tutor always accurate?", 
                                answer: "While our Gemini-powered AI is incredibly advanced, it can occasionally make mistakes or 'hallucinate'. We highly recommend doing a quick review of your AI-generated flashcards against your source material before relying on them for major exams."
                              ),
                              const SizedBox(height: 20),
                              _AnimatedFAQItem(
                                isDark: isDark, 
                                question: "Do I need an internet connection to study?", 
                                answer: "You can review your existing flashcards and decks completely offline on the mobile app! However, creating new AI flashcards, chatting with the AI Tutor, syncing across devices, and accessing the web app requires an active internet connection."
                              ),
                              const SizedBox(height: 20),
                              _AnimatedFAQItem(
                                isDark: isDark, 
                                question: "Can I cancel my Pro subscription?", 
                                answer: "Absolutely. You can cancel your subscription at any time through the Apple App Store or Google Play Store settings. You will retain all your Pro features until the end of your current billing cycle."
                              ),
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
              child: WebNavBar(activePage: "FAQ", onActionTap: () => _launchWebApp(context)),
            ),
          ],
        ),
        ),
      ),
    );
  }

  // ===========================================================================
  // SECTION: BOTTOM CTA
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
                  "Still have questions?",
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
                  "Reach out to our support team and we'll be happy to help.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isMobile ? 16 : 20,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 40),
                HoverScale(
                  onTap: () {
                    // Could link directly to email or contact form
                  },
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
                      "Contact Support",
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
      context.go('/dashboard');
    } else {
      context.go('/login');
    }
  }
}

// =============================================================================
// 🛡️ CUSTOM INTERACTIVE WIDGET: Animated Expandable FAQ Item
// =============================================================================
class _AnimatedFAQItem extends StatefulWidget {
  final bool isDark;
  final String question;
  final String answer;

  const _AnimatedFAQItem({
    required this.isDark,
    required this.question,
    required this.answer,
  });

  @override
  State<_AnimatedFAQItem> createState() => _AnimatedFAQItemState();
}

class _AnimatedFAQItemState extends State<_AnimatedFAQItem> with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  bool _isHovered = false;
  
  late AnimationController _rotationController;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this, 
      duration: const Duration(milliseconds: 300)
    );
    // Animates the icon rotation from 0 to 180 degrees (half a turn)
    _rotationAnimation = Tween<double>(begin: 0.0, end: 0.5).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.easeInOutCubic)
    );
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  void _toggleExpand() {
    HapticFeedback.lightImpact();
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _rotationController.forward();
      } else {
        _rotationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: _toggleExpand,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          width: double.infinity,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: _isHovered || _isExpanded
                  ? const Color(0xFF8B4EFF).withValues(alpha: 0.5)
                  : (widget.isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05)),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: _isHovered
                    ? const Color(0xFF8B4EFF).withValues(alpha: 0.15)
                    : Colors.black.withValues(alpha: widget.isDark ? 0.2 : 0.05),
                blurRadius: _isHovered ? 30 : 20,
                offset: Offset(0, _isHovered ? 15 : 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      widget.question,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _isExpanded || _isHovered
                            ? const Color(0xFF8B4EFF)
                            : Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _isExpanded
                          ? const Color(0xFF8B4EFF).withValues(alpha: 0.1)
                          : (widget.isDark ? Colors.white12 : Colors.grey.shade100),
                      shape: BoxShape.circle,
                    ),
                    child: RotationTransition(
                      turns: _rotationAnimation,
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: _isExpanded
                            ? const Color(0xFF8B4EFF)
                            : (widget.isDark ? Colors.white54 : Colors.black54),
                      ),
                    ),
                  ),
                ],
              ),
              
              // 🛡️ Smoothly reveals the answer when expanded
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOutCubic,
                alignment: Alignment.topCenter,
                child: _isExpanded
                    ? Padding(
                        padding: const EdgeInsets.only(top: 20.0),
                        child: Text(
                          widget.answer,
                          style: TextStyle(
                            fontSize: 16,
                            height: 1.6,
                            color: widget.isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                      )
                    : const SizedBox(width: double.infinity, height: 0), // Keeps structural width
              ),
            ],
          ),
        ),
      ),
    );
  }
}