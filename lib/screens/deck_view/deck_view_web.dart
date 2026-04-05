import 'package:flutter/material.dart';
import '../../models/deck_model.dart';
import '../../models/card_model.dart';

class DeckViewWeb extends StatelessWidget {
  final Deck deck;
  final List<Flashcard> cards;
  final bool isLoading;
  
  final VoidCallback onSettings;
  final VoidCallback onAddCard;
  final Function(Flashcard) onEditCard;
  final Function(String) onDeleteCard;
  final void Function(int, int) onReorderCards;
  final bool isSelectionMode;
  final Set<String> selectedCards;
  final VoidCallback onToggleSelectionMode;
  final Function(String) onToggleCardSelection;
  final VoidCallback onClearSelection;
  final VoidCallback onDeleteSelected;
  final VoidCallback onReview;
  final VoidCallback onFlaggedReview;
  final VoidCallback onQuiz;
  final VoidCallback onAITutor;
  final Function(String) onDisabledAction;

  const DeckViewWeb({
    super.key,
    required this.deck,
    required this.cards,
    required this.isLoading,
    required this.onSettings,
    required this.onAddCard,
    required this.onEditCard,
    required this.onDeleteCard,
    required this.onReorderCards,
    required this.isSelectionMode,
    required this.selectedCards,
    required this.onToggleSelectionMode,
    required this.onToggleCardSelection,
    required this.onClearSelection,
    required this.onDeleteSelected,
    required this.onReview,
    required this.onFlaggedReview,
    required this.onQuiz,
    required this.onAITutor,
    required this.onDisabledAction,
  });

  final LinearGradient _brandGradient = const LinearGradient(
    colors: [Color(0xFF8B4EFF), Color(0xFFE841A1)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final int totalCards = cards.length;
    final int masteredCards = cards.where((c) => c.isMastered).length;
    final int flaggedCards = cards.where((c) => c.isFlagged).length;
    
    final bool canStudy = totalCards > 0;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ==========================================
          // LEFT SIDEBAR: Context & Actions
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
                // 1. Navigation & Settings
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.arrow_back_rounded, size: 20, color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7)),
                            const SizedBox(width: 8),
                            Text(
                              "Library",
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
                    IconButton(
                      icon: Icon(Icons.settings_outlined, color: Theme.of(context).textTheme.bodyMedium?.color),
                      tooltip: "Deck Settings",
                      onPressed: onSettings,
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // 2. Deck Identity
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    deck.subject.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  deck.name,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 32),

                // 3. Deck Statistics (Gestalt Grouping)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.03) : const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade200,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStatColumn(context, "Cards", totalCards.toString(), Colors.blue),
                      _buildStatColumn(context, "Mastered", masteredCards.toString(), Colors.green),
                      _buildStatColumn(context, "Flagged", flaggedCards.toString(), Colors.orange),
                    ],
                  ),
                ),
                const SizedBox(height: 36),

                // 4. Primary Actions (Fitts's Law & Visual Hierarchy)
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: canStudy ? onReview : () => onDisabledAction("Add some cards before reviewing!"),
                    icon: const Icon(Icons.school_rounded, color: Colors.white),
                    label: const Text(
                      "Start Review",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5),
                    ),
                    style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 4,
                      shadowColor: const Color(0xFF8B4EFF).withValues(alpha: 0.4),
                    ),
                  ),
                ).wrapWithGradient(_brandGradient, borderRadius: 14),

                const SizedBox(height: 12),

                // Secondary Actions
                if (flaggedCards > 0) ...[
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: onFlaggedReview,
                      icon: const Icon(Icons.flag_rounded, color: Colors.orange, size: 20),
                      label: Text("Review Flagged ($flaggedCards)", style: const TextStyle(fontWeight: FontWeight.w600)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        side: BorderSide(color: isDark ? Colors.white24 : Colors.black12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: OutlinedButton.icon(
                          onPressed: canStudy && totalCards >= 4 ? onQuiz : () => onDisabledAction("You need at least 4 cards for a Quiz!"),
                          icon: const Icon(Icons.quiz_rounded, size: 18),
                          label: const Text("Quiz", style: TextStyle(fontWeight: FontWeight.w600)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            side: BorderSide(color: isDark ? Colors.white24 : Colors.black12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: OutlinedButton.icon(
                          onPressed: onAITutor,
                          icon: const Icon(Icons.auto_awesome_rounded, color: Color(0xFF8B4EFF), size: 18),
                          label: const Text("AI Tutor", style: TextStyle(fontWeight: FontWeight.w600)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            side: BorderSide(color: isDark ? Colors.white24 : Colors.black12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ==========================================
          // RIGHT PANE: Flashcard Management
          // ==========================================
          Expanded(
            child: Container(
              color: isDark ? const Color(0xFF0D0A14) : const Color(0xFFF4F6FF),
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : CustomScrollView(
                      slivers: [
                        // Header Bar
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(40, 40, 40, 24),
                            child: Row(
                              children: [
                                Text(
                                  "Flashcards",
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).textTheme.bodyLarge?.color,
                                  ),
                                ),
                                const Spacer(),
                            if (isSelectionMode) ...[
                              Text(
                                "${selectedCards.length} Selected",
                                style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color),
                              ),
                              const SizedBox(width: 16),
                              ElevatedButton.icon(
                                onPressed: onDeleteSelected,
                                icon: const Icon(Icons.delete_sweep_rounded, size: 18),
                                label: const Text("Delete", style: TextStyle(fontWeight: FontWeight.bold)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.redAccent,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                              const SizedBox(width: 8),
                              TextButton(
                                onPressed: onClearSelection,
                                child: const Text("Cancel", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                              ),
                            ] else ...[
                              if (cards.isNotEmpty)
                                OutlinedButton.icon(
                                  onPressed: onToggleSelectionMode,
                                  icon: const Icon(Icons.checklist_rounded, size: 18),
                                  label: const Text("Select", style: TextStyle(fontWeight: FontWeight.bold)),
                                  style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                                ),
                              const SizedBox(width: 12),
                              ElevatedButton.icon(
                                onPressed: onAddCard,
                                icon: const Icon(Icons.add_rounded, size: 20),
                                label: const Text("Add Card", style: TextStyle(fontWeight: FontWeight.w600)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isDark ? Colors.white12 : Colors.white,
                                  foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(color: isDark ? Colors.white24 : Colors.grey.shade300),
                                  ),
                                ),
                              ),
                            ]
                              ],
                            ),
                          ),
                        ),

                        // Empty State
                        if (cards.isEmpty)
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.style_rounded, size: 80, color: Theme.of(context).dividerColor),
                                  const SizedBox(height: 24),
                                  Text(
                                    "This deck is empty",
                                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    "Add some cards manually or use the AI Tutor.",
                                    style: TextStyle(fontSize: 15, color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7)),
                                  ),
                                  const SizedBox(height: 32),
                                  ElevatedButton.icon(
                                    onPressed: onAddCard,
                                    icon: const Icon(Icons.add_rounded, color: Colors.white),
                                    label: const Text("Create First Card", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF8B4EFF),
                                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          // Grid of Cards (Responsive & Ergonomic Constraint)
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(40, 0, 40, 40),
                            sliver: SliverGrid(
                              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 400, // Prevents cards from stretching too wide
                                mainAxisSpacing: 20,
                                crossAxisSpacing: 20,
                                mainAxisExtent: 220, // Fixed height for visual consistency
                              ),
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final card = cards[index];
                                  return _buildWebFlashcard(context, card, isDark);
                                },
                                childCount: cards.length,
                              ),
                            ),
                          ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(BuildContext context, String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWebFlashcard(BuildContext context, Flashcard card, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Action Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (card.isMastered)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: const Text("MASTERED", style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                )
              else if (card.isFlagged)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: const Text("FLAGGED", style: TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold)),
                )
              else
                const SizedBox.shrink(),
              
              Row(
                children: [
                  IconButton(
                    onPressed: () => onEditCard(card),
                    icon: Icon(Icons.edit_rounded, color: isDark ? Colors.white54 : Colors.black45, size: 18),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    tooltip: "Edit Card",
                  ),
                  IconButton(
                    onPressed: () => onDeleteCard(card.id),
                    icon: Icon(Icons.delete_rounded, color: isDark ? Colors.redAccent.shade200 : Colors.redAccent, size: 18),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    tooltip: "Delete Card",
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Question text
          Expanded(
            flex: 3,
            child: Text(
              card.question,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyLarge?.color,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          
          Divider(height: 24, thickness: 1, color: isDark ? Colors.white12 : const Color(0xFFF0F0F0)),
          
          // Answer text
          Expanded(
            flex: 4,
            child: Text(
              card.answer,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Helper extension to easily wrap buttons in a gradient
extension GradientWrapper on Widget {
  Widget wrapWithGradient(LinearGradient gradient, {double borderRadius = 0}) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: this,
    );
  }
}