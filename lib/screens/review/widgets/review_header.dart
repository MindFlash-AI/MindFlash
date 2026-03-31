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

  Future<void> _showShuffleConfirmation(BuildContext context) async {
    HapticFeedback.lightImpact();
    
    final bool? confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: true, // Allows tapping outside to cancel
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        
        return AlertDialog(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 12,
          title: Row(
            children: [
              const Icon(Icons.shuffle_rounded, color: Color(0xFF8B4EFF)),
              const SizedBox(width: 10),
              Text(
                "Shuffle Deck?",
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          content: Text(
            "This will restart your current review session and randomize the remaining cards. Are you sure?",
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.black87,
              height: 1.4,
              fontSize: 15,
            ),
          ),
          actionsAlignment: MainAxisAlignment.end,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                Navigator.pop(context, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B4EFF),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: const Text(
                "Shuffle",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );

    // If the user clicks "Shuffle", we trigger the original callback
    if (confirm == true) {
      onShuffle();
    }
  }

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
            onPressed: () => _showShuffleConfirmation(context),
            tooltip: 'Shuffle Cards',
          ),
        ],
      ),
    );
  }
}