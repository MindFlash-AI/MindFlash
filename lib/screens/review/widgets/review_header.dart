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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.white70),
            onPressed: onExit,
            tooltip: 'Exit Review',
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF23173D), // Dark elevated pill
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Card ${currentIndex + 1} of $totalCards',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.shuffle_rounded, color: Colors.white70),
            onPressed: onShuffle,
            tooltip: 'Shuffle Cards',
          ),
        ],
      ),
    );
  }
}