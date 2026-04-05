import 'package:flutter/material.dart';

class QuizStatsRow extends StatelessWidget {
  final int correctCount;
  final int incorrectCount;
  final int remainingCount;

  const QuizStatsRow({
    super.key,
    required this.correctCount,
    required this.incorrectCount,
    required this.remainingCount,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStatBadge(
            Icons.check_circle_rounded,
            isDark ? Colors.greenAccent.shade400 : Colors.green.shade600,
            '$correctCount',
          ),
          _buildStatBadge(
            Icons.cancel_rounded,
            isDark ? Colors.redAccent.shade200 : Colors.red.shade500,
            '$incorrectCount',
          ),
          _buildStatBadge(
            Icons.help_outline_rounded,
            isDark ? Colors.white54 : Colors.grey.shade500,
            '$remainingCount',
          ),
        ],
      ),
    );
  }

  Widget _buildStatBadge(IconData icon, Color color, String text) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}
