import 'package:flutter/material.dart';

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
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeOutBack,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, animation) {
          return ScaleTransition(
            scale: animation,
            child: FadeTransition(
              opacity: animation,
              child: child,
            ),
          );
        },
        child: showAnswer
            ? Row(
                key: const ValueKey('answer_buttons'),
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: _buildActionButton(
                      label: "Need Review",
                      icon: Icons.repeat_rounded,
                      color: Colors.redAccent.shade200, // Brighter for dark mode
                      onPressed: onIncorrect,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildActionButton(
                      label: "Got It",
                      icon: Icons.check_rounded,
                      color: Colors.greenAccent.shade400, // Brighter for dark mode
                      onPressed: onCorrect,
                      isPrimary: true,
                    ),
                  ),
                ],
              )
            : SizedBox(
                key: const ValueKey('placeholder_box'),
                width: double.infinity,
                height: 56, // Matches the height of the buttons above
                child: Center(
                  child: Text(
                    "Flip card to reveal answer",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.3),
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    bool isPrimary = false,
  }) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: isPrimary ? color.withOpacity(0.15) : Colors.transparent,
        border: Border.all(
          color: isPrimary ? color : color.withOpacity(0.5),
          width: 2,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}