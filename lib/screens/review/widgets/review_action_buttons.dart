import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ReviewActionButtons extends StatelessWidget {
  final bool showAnswer;
  final VoidCallback onCorrect;
  final VoidCallback onIncorrect;

  const ReviewActionButtons({
    super.key,
    required this.showAnswer,
    required this.onCorrect,
    required this.onIncorrect,
  });

  @override
  Widget build(BuildContext context) {
    if (!showAnswer) {
      return Container(
        height: 60,
        alignment: Alignment.center,
        child: Text(
          "Flip card to reveal answer",
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark 
                ? Colors.white54 
                : Colors.grey.shade600,
            fontStyle: FontStyle.italic,
            fontSize: 15,
          ),
        ),
      );
    }

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          Expanded(
            child: _buildActionButton(
              context: context,
              label: "Need Review",
              icon: Icons.close_rounded,
              color: const Color(0xFFFF5252),
              onTap: onIncorrect,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildActionButton(
              context: context,
              label: "Got It",
              icon: Icons.check_rounded,
              color: const Color(0xFF69F0AE),
              onTap: onCorrect,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color.withValues(alpha: isDark ? 0.15 : 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withValues(alpha: isDark ? 0.6 : 1.0), 
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: isDark ? color : color.withValues(alpha: 0.9), size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isDark ? color : color.withValues(alpha: 0.9),
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}