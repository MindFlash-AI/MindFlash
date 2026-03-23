import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

  Future<bool?> _confirmShuffle(BuildContext context) {
    HapticFeedback.heavyImpact();
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            "Shuffle Cards?",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text(
            "This will restart your review session and reshuffle the cards. Are you sure?",
            style: TextStyle(color: Colors.black87),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5A6DFF).withOpacity(0.1),
                foregroundColor: const Color(0xFF5A6DFF),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                "Shuffle",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: TextButton.icon(
              onPressed: onExit,
              icon: const Icon(Icons.arrow_back, color: Colors.black87, size: 18),
              label: const Text(
                "Exit",
                style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          Text(
            "${currentIndex + 1} / $totalCards",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          IconButton(
            icon: const Icon(Icons.shuffle, color: Colors.black87, size: 20),
            onPressed: () async {
              HapticFeedback.selectionClick();
              final bool? confirm = await _confirmShuffle(context);
              if (confirm == true) {
                onShuffle();
              }
            },
          ),
        ],
      ),
    );
  }
}