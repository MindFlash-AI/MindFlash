import 'package:flutter/material.dart';

class SessionStatsBar extends StatelessWidget {
  final int correctCount;
  final int incorrectCount;

  const SessionStatsBar({
    super.key,
    required this.correctCount,
    required this.incorrectCount,
  });

  @override
  Widget build(BuildContext context) {
    int totalAnswered = correctCount + incorrectCount;
    String percentStr = totalAnswered == 0 
        ? "--%" 
        : "${((correctCount / totalAnswered) * 100).round()}%";

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _StatBadge(
            icon: Icons.check_circle_rounded,
            value: correctCount.toString(),
            color: Colors.green,
            bgColor: Colors.green.shade50,
          ),
          const SizedBox(width: 12),
          _StatBadge(
            icon: Icons.flag_rounded,
            value: incorrectCount.toString(),
            color: Colors.redAccent,
            bgColor: Colors.red.shade50,
          ),
          const SizedBox(width: 12),
          _StatBadge(
            icon: Icons.pie_chart_rounded,
            value: percentStr,
            color: const Color(0xFF5A6DFF),
            bgColor: const Color(0xFFF4F6FF),
          ),
        ],
      ),
    );
  }
}

// Extracted private component to adhere to DRY principle
class _StatBadge extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color color;
  final Color bgColor;

  const _StatBadge({
    required this.icon,
    required this.value,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}