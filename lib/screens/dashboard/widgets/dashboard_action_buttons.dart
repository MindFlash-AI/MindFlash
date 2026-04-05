import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DashboardActionButtons extends StatelessWidget {
  final bool isDark;
  final double maxWidth;
  final AnimationController pulseController;
  final VoidCallback onManualDeckTap;
  final VoidCallback onQuickScanTap;
  final VoidCallback onAIOptionsTap;
  final VoidCallback onStudyPadTap;

  const DashboardActionButtons({
    super.key,
    required this.isDark,
    required this.maxWidth,
    required this.pulseController,
    required this.onManualDeckTap,
    required this.onQuickScanTap,
    required this.onAIOptionsTap,
    required this.onStudyPadTap,
  });

  @override
  Widget build(BuildContext context) {
    if (maxWidth >= 850) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildCompactButton(
            context,
            isDark,
            label: "Manual Deck",
            icon: Icons.add,
            onTap: onManualDeckTap,
            isPrimary: false,
          ),
          const SizedBox(width: 12),
          _buildCompactButton(
            context,
            isDark,
            label: "Quick Scan",
            icon: Icons.document_scanner_rounded,
            onTap: onQuickScanTap,
            isPrimary: false,
            color: const Color(0xFF8B4EFF),
          ),
          const SizedBox(width: 12),
          AnimatedBuilder(
            animation: pulseController,
            builder: (context, child) {
              final scale = 1.0 +
                  0.03 *
                      (0.5 *
                          (1 +
                              ((pulseController.value * 2 - 1).abs() - 0.5) *
                                  2));
              return Transform.scale(scale: scale, child: child);
            },
            child: _buildCompactButton(
              context,
              isDark,
              label: "Generate with AI",
              icon: Icons.auto_awesome,
              onTap: onAIOptionsTap,
              isPrimary: true,
            ),
          ),
        ],
      );
    } else {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: pulseController,
            builder: (context, child) {
              final scale = 1.0 +
                  0.05 *
                      (0.5 *
                          (1 +
                              ((pulseController.value * 2 - 1).abs() - 0.5) *
                                  2));
              return Transform.scale(scale: scale, child: child);
            },
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 55,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [Color(0xFF2C1A8A), Color(0xFF5B4FE6)]),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF8B4EFF).withValues(alpha: 0.4),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        )
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          onAIOptionsTap();
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.auto_awesome, color: Colors.white),
                            SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                "Generate with AI",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  height: 55,
                  width: 55,
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: isDark
                        ? Border.all(
                            color: Colors.white.withValues(alpha: 0.05),
                            width: 1)
                        : Border.all(
                            color:
                                const Color(0xFF8B4EFF).withValues(alpha: 0.3),
                            width: 1.5),
                    boxShadow: [
                      BoxShadow(
                          color: const Color(0xFF8B4EFF).withValues(alpha: 0.15),
                          blurRadius: 12,
                          offset: const Offset(0, 4))
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: onQuickScanTap,
                      child: const Center(
                        child: Icon(Icons.document_scanner_rounded,
                            color: Color(0xFF8B4EFF), size: 24),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 55,
                  decoration: BoxDecoration(
                    color:
                        isDark ? const Color(0xFF2A1B3D) : Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: const Color(0xFF8B4EFF).withValues(alpha: 0.5),
                        width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF8B4EFF).withValues(alpha: 0.1),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        onStudyPadTap();
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.edit_note_rounded,
                              color: Color(0xFF8B4EFF)),
                          SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              "Study Pad",
                              style: TextStyle(
                                  color: Color(0xFF8B4EFF),
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  height: 55,
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: isDark
                        ? Border.all(
                            color: Colors.white.withValues(alpha: 0.05),
                            width: 1)
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color:
                            Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        onManualDeckTap();
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add,
                              color: Theme.of(context).textTheme.bodyLarge?.color,
                              size: 20),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              "Manual Deck",
                              style: TextStyle(
                                color: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.color,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
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
        ],
      );
    }
  }

  Widget _buildCompactButton(
    BuildContext context,
    bool isDark, {
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    required bool isPrimary,
    Color? color,
  }) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        gradient: isPrimary
            ? const LinearGradient(
                colors: [Color(0xFF2C1A8A), Color(0xFF5B4FE6)])
            : null,
        color: isPrimary ? null : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: isPrimary
            ? null
            : Border.all(
                color: color?.withValues(alpha: 0.5) ??
                    (isDark ? Colors.white24 : Colors.grey.shade200),
                width: 1,
              ),
        boxShadow: isPrimary
            ? [
                BoxShadow(
                    color: const Color(0xFF8B4EFF).withValues(alpha: isDark ? 0.4 : 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8))
              ]
            : [
                BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                    blurRadius: 16,
                    offset: const Offset(0, 6))
              ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon,
                    color: isPrimary
                        ? Colors.white
                        : (color ??
                            Theme.of(context).textTheme.bodyLarge?.color),
                    size: 20),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: isPrimary
                        ? Colors.white
                        : (color ??
                            Theme.of(context).textTheme.bodyLarge?.color),
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
