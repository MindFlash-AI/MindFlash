import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/pro_service.dart';
import '../constants/constants.dart';

class ProPaywallSheet extends StatefulWidget {
  final String? customTitle;
  final String? customSubtitle;

  const ProPaywallSheet({super.key, this.customTitle, this.customSubtitle});

  /// Universal method to show the paywall from anywhere in the app
  /// Transformed to a full-screen dialog overlay
  static Future<void> show(BuildContext context, {String? title, String? subtitle}) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ProPaywallSheet(
          customTitle: title,
          customSubtitle: subtitle,
        ),
        fullscreenDialog: true, // Slides up from the bottom like a premium overlay
      ),
    );
  }

  @override
  State<ProPaywallSheet> createState() => _ProPaywallSheetState();
}

class _ProPaywallSheetState extends State<ProPaywallSheet> with SingleTickerProviderStateMixin {
  bool _isProcessing = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    // Setup a subtle pulsing animation for the premium icon
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _purchasePro() async {
    HapticFeedback.heavyImpact();
    setState(() => _isProcessing = true);

    bool success = await ProService().purchasePro();
    
    if (!mounted) return;

    setState(() => _isProcessing = false);
    
    if (success) {
      // CAPTURE the messenger and navigator before popping
      final messenger = ScaffoldMessenger.of(context);
      final navigator = Navigator.of(context);
      
      navigator.pop(); // Close the fullscreen sheet
      
      // Use the captured messenger
      messenger.showSnackBar(
        const SnackBar(content: Text("Welcome to MindFlash Pro! 🎉"), backgroundColor: Colors.green),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Purchase canceled or failed. Please try again.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Background Aesthetic Gradients
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.pinkStart.withValues(alpha: isDark ? 0.15 : 0.08),
                boxShadow: [
                  BoxShadow(color: AppColors.pinkStart.withValues(alpha: isDark ? 0.2 : 0.1), blurRadius: 100),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.blueStart.withValues(alpha: isDark ? 0.15 : 0.08),
                boxShadow: [
                  BoxShadow(color: AppColors.blueStart.withValues(alpha: isDark ? 0.2 : 0.1), blurRadius: 100),
                ],
              ),
            ),
          ),
          
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header / Close Button
                Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: IconButton(
                      icon: Icon(Icons.close_rounded, size: 28, color: isDark ? Colors.white70 : Colors.black87),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ),
                
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        
                        // Animated Glowing Premium Icon
                        AnimatedBuilder(
                          animation: _pulseAnimation,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _pulseAnimation.value,
                              child: Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.pinkStart.withValues(alpha: 0.2),
                                      AppColors.blueStart.withValues(alpha: 0.2)
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.pinkStart.withValues(alpha: 0.3),
                                      blurRadius: 30,
                                      spreadRadius: 5,
                                    ),
                                  ],
                                ),
                                child: const Icon(Icons.workspace_premium_rounded, size: 80, color: AppColors.pinkStart),
                              ),
                            );
                          }
                        ),
                        
                        const SizedBox(height: 40),
                        
                        // Dynamic Marketing Text
                        Text(
                          widget.customTitle ?? "MindFlash Pro",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 32, 
                            fontWeight: FontWeight.w900, 
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                            letterSpacing: -0.5,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          widget.customSubtitle ?? "Unlock your ultimate study potential and learn faster than ever before.",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16, color: isDark ? Colors.white70 : Colors.grey.shade700, height: 1.5),
                        ),
                        
                        const SizedBox(height: 48),
                        
                        // Feature List
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor.withValues(alpha: isDark ? 0.5 : 1.0),
                            borderRadius: BorderRadius.circular(24),
                            border: isDark ? Border.all(color: Colors.white.withValues(alpha: 0.05)) : null,
                            boxShadow: [
                              if (!isDark) BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 4)),
                            ],
                          ),
                          child: Column(
                            children: [
                              _buildProFeature(Icons.bolt_rounded, "Double AI Energy", "30 daily energy limits instead of 15", isDark, AppColors.pinkStart),
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                child: Divider(height: 1, color: isDark ? Colors.white12 : Colors.grey.shade200),
                              ),
                              _buildProFeature(Icons.ad_units_rounded, "Ad-Free Studying", "Zero interruptions to your flow", isDark, AppColors.blueStart),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
                
                // Bottom Action Area
                Container(
                  padding: const EdgeInsets.all(24).copyWith(bottom: 32),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.0),
                        Theme.of(context).scaffoldBackgroundColor,
                        Theme.of(context).scaffoldBackgroundColor,
                      ],
                    ),
                  ),
                  child: Column(
                    children: [
                      if (_isProcessing)
                        const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: CircularProgressIndicator(color: AppColors.pinkStart),
                        )
                      else
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            gradient: const LinearGradient(
                              colors: [AppColors.pinkStart, AppColors.blueStart],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            boxShadow: [
                              BoxShadow(color: AppColors.pinkStart.withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 8)),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: _purchasePro,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              minimumSize: const Size(double.infinity, 64),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            ),
                            child: const Text(
                              "Subscribe for \$1.00 / month", 
                              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)
                            ),
                          ),
                        ),
                      
                      const SizedBox(height: 16),
                      
                      TextButton(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          Navigator.pop(context);
                        },
                        style: TextButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        child: Text(
                          "Not right now", 
                          style: TextStyle(color: isDark ? Colors.white54 : Colors.grey.shade600, fontSize: 15, fontWeight: FontWeight.w600)
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProFeature(IconData icon, String title, String subtitle, bool isDark, Color iconColor) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.15), 
            borderRadius: BorderRadius.circular(16)
          ),
          child: Icon(icon, color: iconColor, size: 28),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title, 
                style: TextStyle(
                  fontSize: 17, 
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87
                )
              ),
              const SizedBox(height: 4),
              Text(
                subtitle, 
                style: TextStyle(
                  fontSize: 14, 
                  color: isDark ? Colors.white60 : Colors.black54,
                  height: 1.3,
                )
              ),
            ],
          ),
        ),
      ],
    );
  }
}