import 'package:flutter/material.dart';

class SessionStatsBar extends StatelessWidget {
  final int correctCount;
  final int incorrectCount;

  const SessionStatsBar({
    super.key,
    required this.correctCount,
    required this.incorrectCount,
  });

  Widget _buildStat(IconData icon, Color color, String text) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            color: color.withOpacity(0.9),
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildStat(
            Icons.check_circle_rounded,
            Colors.greenAccent.shade400, // Brighter green for dark mode
            '$correctCount Got It',
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Container(
              height: 12,
              width: 2,
              color: Colors.white24, // Dark mode divider
            ),
          ),
          _buildStat(
            Icons.cancel_rounded,
            Colors.redAccent.shade200, // Brighter red for dark mode
            '$incorrectCount Review',
          ),
        ],
      ),
    );
  }
}