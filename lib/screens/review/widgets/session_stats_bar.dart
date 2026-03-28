import 'package:flutter/material.dart';

class SessionStatsBar extends StatelessWidget {
  final int correctCount;
  final int incorrectCount;

  const SessionStatsBar({
    super.key,
    required this.correctCount,
    required this.incorrectCount,
  });

  Widget _buildStat(IconData icon, Color color, String text, bool isDark) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            color: isDark ? color.withOpacity(0.9) : color.withOpacity(0.8),
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildStat(
            Icons.check_circle_rounded,
            isDark ? Colors.greenAccent.shade400 : Colors.green.shade600,
            '$correctCount Got It',
            isDark,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Container(
              height: 12,
              width: 2,
              color: isDark ? Colors.white24 : Colors.grey.shade300,
            ),
          ),
          _buildStat(
            Icons.cancel_rounded,
            isDark ? Colors.redAccent.shade200 : Colors.red.shade500,
            '$incorrectCount Review',
            isDark,
          ),
        ],
      ),
    );
  }
}