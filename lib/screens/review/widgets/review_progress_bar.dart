import 'package:flutter/material.dart';

class ReviewProgressBar extends StatelessWidget {
  final int currentIndex;
  final int totalCards;

  const ReviewProgressBar({
    super.key,
    required this.currentIndex,
    required this.totalCards,
  });

  @override
  Widget build(BuildContext context) {
    double progress = totalCards == 0 ? 0 : (currentIndex + 1) / totalCards;
    
    return Container(
      height: 6,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(3),
      ),
      alignment: Alignment.centerLeft,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        width: MediaQuery.of(context).size.width * progress,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(3),
          gradient: const LinearGradient(
            colors: [Color(0xFF5A6DFF), Color(0xFFE335A0)],
          ),
        ),
      ),
    );
  }
}