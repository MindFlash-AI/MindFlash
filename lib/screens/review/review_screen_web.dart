import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/deck_model.dart';
import '../../models/card_model.dart';
import 'widgets/review_progress_bar.dart';
import 'widgets/session_stats_bar.dart';
import 'widgets/flashcard_stack_view.dart';
import '../../widgets/floating_tutor_button.dart';

class ReviewScreenWeb extends StatelessWidget {
  final Deck deck;
  final List<Flashcard> reviewCards;
  final int currentIndex;
  final PageController pageController;
  final int correctCount;
  final int incorrectCount;
  final bool canUndo;
  final VoidCallback onUndo;
  
  final VoidCallback onExit;
  final VoidCallback onShuffle;
  final Function(int) onPageChanged;
  final Function(bool) onFlip;
  final VoidCallback onCorrect;
  final VoidCallback onIncorrect;
  final Function(Flashcard) onExplainRequested;

  const ReviewScreenWeb({
    super.key,
    required this.deck,
    required this.reviewCards,
    required this.currentIndex,
    required this.pageController,
    required this.correctCount,
    required this.incorrectCount,
    required this.canUndo,
    required this.onUndo,
    required this.onExit,
    required this.onShuffle,
    required this.onPageChanged,
    required this.onFlip,
    required this.onCorrect,
    required this.onIncorrect,
    required this.onExplainRequested,
  });

  Future<void> _showShuffleConfirmation(BuildContext context) async {
    HapticFeedback.lightImpact();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Shuffle Deck?", style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
        content: Text(
          "This will restart your current review session in a random order.",
          style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B4EFF),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("Shuffle", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      onShuffle();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totalCards = reviewCards.length;
    final progress = totalCards > 0 ? (currentIndex + 1) / totalCards : 0.0;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Row(
        children: [
          // ==========================================
          // LEFT SIDEBAR: Navigation, Context, Analytics
          // ==========================================
          Container(
            width: 340,
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              border: Border(
                right: BorderSide(
                  color: Theme.of(context).dividerColor.withValues(alpha: isDark ? 0.2 : 0.5),
                  width: 1,
                ),
              ),
              boxShadow: [
                if (!isDark)
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 15,
                    offset: const Offset(3, 0),
                  ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Navigation / Back (Fitts's Law: Enlarge target area)
                InkWell(
                  onTap: onExit,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.arrow_back_rounded, 
                          size: 20, 
                          color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7)
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Back to Deck",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 36),

                // 2. Deck Contextual Info
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B4EFF).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    "REVIEW SESSION",
                    style: TextStyle(
                      fontSize: 11,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF8B4EFF),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  deck.name,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 36),

                // 3. Stats & Progress (Gestalt Law of Enclosure)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.03) : const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade200,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Session Progress",
                        style: TextStyle(
                          fontSize: 14, 
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ReviewProgressBar(currentIndex: currentIndex, totalCards: reviewCards.length),
                      const SizedBox(height: 24),
                      Divider(height: 1, color: isDark ? Colors.white12 : Colors.black12),
                      const SizedBox(height: 24),
                      Text(
                        "Performance",
                        style: TextStyle(
                          fontSize: 14, 
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SessionStatsBar(
                        correctCount: correctCount,
                        incorrectCount: incorrectCount,
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // 4. Utility Actions
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: canUndo ? onUndo : null,
                    icon: const Icon(Icons.undo_rounded, size: 20),
                    label: const Text(
                      "Undo Last Card",
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
                      side: BorderSide(
                        color: isDark ? Colors.white24 : Colors.black12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _showShuffleConfirmation(context),
                    icon: const Icon(Icons.shuffle_rounded, size: 20),
                    label: const Text(
                      "Shuffle Deck",
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
                      side: BorderSide(
                        color: isDark ? Colors.white24 : Colors.black12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ==========================================
          // MAIN CONTENT AREA: Flashcard & Tutor
          // ==========================================
          Expanded(
            child: Container(
              color: isDark ? const Color(0xFF0D0A14) : const Color(0xFFF4F6FF),
              child: Stack(
                children: [
                  // Flashcard Stack aligned centrally with constraints
                  Center(
                    child: ConstrainedBox(
                      // Limit width to maintain readability (HCI line-length principle)
                      constraints: const BoxConstraints(maxWidth: 850),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 32.0),
                        child: FlashcardStackView(
                          cards: reviewCards,
                          currentIndex: currentIndex,
                          pageController: pageController,
                          onPageChanged: onPageChanged,
                          onFlip: onFlip,
                          onCorrect: onCorrect,
                          onIncorrect: onIncorrect,
                          onExplainRequested: onExplainRequested,
                        ),
                      ),
                    ),
                  ),
                  
                  // AI Tutor placed in the conventional bottom-right corner 
                  // to match universal mental models for "Assistants/Chat"
                  Positioned(
                    bottom: 40,
                    right: 40,
                    child: FloatingTutorButton(deck: deck),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}