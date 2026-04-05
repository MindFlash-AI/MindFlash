import 'package:flutter/material.dart';

class DeckActionButtons extends StatelessWidget {
  final bool canReview;
  final bool canQuiz;
  final bool hasFlagged;
  final int flaggedCount;
  final VoidCallback onReview;
  final VoidCallback onFlaggedReview;
  final VoidCallback onQuiz;
  final VoidCallback onAITutor;
  final Function(String) onDisabledAction;
  final LinearGradient brandGradient;

  const DeckActionButtons({
    super.key,
    required this.canReview,
    required this.canQuiz,
    required this.hasFlagged,
    required this.flaggedCount,
    required this.onReview,
    required this.onFlaggedReview,
    required this.onQuiz,
    required this.onAITutor,
    required this.onDisabledAction,
    required this.brandGradient,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Opacity(
            opacity: canReview ? 1.0 : 0.5,
            child: Container(
              height: 60,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: brandGradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  if (canReview)
                    BoxShadow(
                        color: const Color(0xFF8B4EFF).withValues(alpha: 0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 8)),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: canReview
                      ? onReview
                      : () => onDisabledAction(
                          "Add some cards first to start a review."),
                  borderRadius: BorderRadius.circular(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.play_circle_fill_rounded,
                          color: Colors.white, size: 28),
                      SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          "Study Entire Deck",
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                              letterSpacing: 0.5),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (hasFlagged) ...[
            const SizedBox(height: 12),
            Container(
              height: 52,
              width: double.infinity,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.red.withValues(alpha: 0.1)
                    : Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: isDark
                        ? Colors.red.withValues(alpha: 0.3)
                        : Colors.red.shade100,
                    width: 1.5),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onFlaggedReview,
                  borderRadius: BorderRadius.circular(12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.flag_rounded,
                          color: isDark
                              ? Colors.redAccent.shade200
                              : Colors.redAccent,
                          size: 20),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          "Focus Weaknesses ($flaggedCount Card${flaggedCount == 1 ? '' : 's'})",
                          style: TextStyle(
                              color: isDark
                                  ? Colors.redAccent.shade200
                                  : Colors.redAccent,
                              fontWeight: FontWeight.w700,
                              fontSize: 15),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ] else ...[
            const SizedBox(height: 16),
          ],
          Row(
            children: [
              Expanded(
                  child: _buildToolButton(
                      context,
                      Icons.quiz_rounded,
                      "Quiz",
                      const Color(0xFFFF9100),
                      canQuiz,
                      onQuiz,
                      "You need at least 4 cards to take a quiz.")),
              const SizedBox(width: 12),
              Expanded(
                  child: _buildToolButton(
                      context,
                      Icons.auto_awesome_rounded,
                      "AI Tutor",
                      const Color(0xFFE841A1),
                      canReview,
                      onAITutor,
                      "Add cards to chat with the tutor.")),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildToolButton(BuildContext context, IconData icon, String label,
      Color color, bool canAct, VoidCallback action, String disabledMsg) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Opacity(
      opacity: canAct ? 1.0 : 0.5,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: canAct ? action : () => onDisabledAction(disabledMsg),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: 76,
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: isDark ? Colors.white12 : Colors.grey.shade300,
                  width: 1.5),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: Text(
                    label,
                    style: TextStyle(
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                        fontSize: 12,
                        fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
