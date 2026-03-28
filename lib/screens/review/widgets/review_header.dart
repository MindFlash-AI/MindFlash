import 'package:flutter/material.dart';

class ReviewHeader extends StatelessWidget {
  final int currentIndex;
  final int totalCards;
  final VoidCallback onExit;
  final VoidCallback onShuffle;

  const ReviewHeader({
    super.key,
    required this.currentIndex,
    required this.totalCards,
    required this.onExit,
    required this.onShuffle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(
              Icons.close_rounded, 
              color: isDark ? Colors.white70 : Colors.black54,
            ),
            onPressed: onExit,
            tooltip: 'Exit Review',
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF23173D) : const Color(0xFF8B4EFF).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Card ${currentIndex + 1} of $totalCards',
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF8B4EFF),
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.shuffle_rounded, 
              color: isDark ? Colors.white70 : Colors.black54,
            ),
            onPressed: onShuffle,
            tooltip: 'Shuffle Cards',
          ),
        ],
      ),
    );
  }
}