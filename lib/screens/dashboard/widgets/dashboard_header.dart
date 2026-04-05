import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../constants/constants.dart';
import '../../../widgets/how_it_works_dialog.dart';
import '../../settings/settings_screen.dart';

class DashboardHeader extends StatefulWidget {
  const DashboardHeader({super.key});

  @override
  State<DashboardHeader> createState() => _DashboardHeaderState();
}

class _DashboardHeaderState extends State<DashboardHeader> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.blueStart, AppColors.pinkStart],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6A5AE0).withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.menu_book_rounded,
            color: Colors.white,
            size: 26,
          ),
        ),
        const SizedBox(width: 14),

        // Wrapped in Expanded to prevent overflow on small screens
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [AppColors.blueStart, AppColors.pinkStart],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ).createShader(bounds),
                child: const Text(
                  "MindFlash",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                "Master anything, anytime",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis, // Ensure text truncates if needed
              ),
            ],
          ),
        ),

        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 🛡️ BUG FIX: Wrapped the Material button in a TapRegion
            // This detects taps anywhere else on the screen and instantly minimizes the button.
            TapRegion(
              onTapOutside: (PointerDownEvent event) {
                if (_isExpanded) {
                  setState(() {
                    _isExpanded = false;
                  });
                }
              },
              child: Material(
                color: const Color(0xFF5B4FE6).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(24),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    if (!_isExpanded) {
                      setState(() {
                        _isExpanded = true;
                      });
                      // Auto hide after 4 seconds to save space again
                      Future.delayed(const Duration(seconds: 4), () {
                        if (mounted && _isExpanded) {
                          setState(() {
                            _isExpanded = false;
                          });
                        }
                      });
                    } else {
                      showDialog(
                        context: context,
                        builder: (context) => const HowItWorksDialog(),
                      );
                    }
                  },
                  child: AnimatedPadding(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    padding: EdgeInsets.symmetric(
                      horizontal: _isExpanded ? 16 : 10, 
                      vertical: 10
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.lightbulb_outline_rounded,
                          size: 18,
                          color: Color(0xFF5B4FE6),
                        ),
                        AnimatedSize(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          alignment: Alignment.centerLeft,
                          child: _isExpanded
                              ? const Padding(
                                  padding: EdgeInsets.only(left: 6),
                                  child: Text(
                                    "How It Works",
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF5B4FE6),
                                    ),
                                    maxLines: 1,
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            
            // Settings Button
            Material(
              color: const Color(0xFF5B4FE6).withValues(alpha: 0.08),
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingsScreen(),
                    ),
                  );
                },
                child: const Padding(
                  padding: EdgeInsets.all(10),
                  child: Icon(
                    Icons.settings_rounded,
                    size: 18,
                    color: Color(0xFF5B4FE6),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}