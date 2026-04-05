import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/deck_model.dart';
import '../../models/card_model.dart';

class DeckViewMobile extends StatelessWidget {
  final Deck deck;
  final List<Flashcard> cards;
  final bool isLoading;
  final ScrollController scrollController;
  final AnimationController actionsExpandController;
  final Animation<double> expandAnimation;
  
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

  const DeckViewMobile({
    super.key,
    required this.deck,
    required this.cards,
    required this.isLoading,
    required this.scrollController,
    required this.actionsExpandController,
    required this.expandAnimation,
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
    
    String firstLetter = deck.name.isNotEmpty
        ? deck.name[0].toUpperCase()
        : "?";

    final bool canReview = cards.isNotEmpty;
    final bool canQuiz = cards.length >= 4;
    final int flaggedCount = cards.where((c) => c.isFlagged).length;
    final bool hasFlagged = flaggedCount > 0;

    final double actionsHeight = hasFlagged ? 248.0 : 184.0;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: isSelectionMode
          ? AppBar(
              backgroundColor: isDark ? const Color(0xFF2A1B3D) : const Color(0xFFF4F6FF),
              elevation: 0,
              leading: IconButton(icon: Icon(Icons.close_rounded, color: Theme.of(context).appBarTheme.foregroundColor), onPressed: onClearSelection),
              title: Text("${selectedCards.length} Selected", style: TextStyle(color: Theme.of(context).appBarTheme.foregroundColor, fontWeight: FontWeight.bold, fontSize: 16)),
              actions: [
                IconButton(
                  icon: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent),
                  onPressed: onDeleteSelected,
                ),
              ],
            )
          : AppBar(
              systemOverlayStyle: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark.copyWith(
                statusBarColor: Colors.transparent,
              ),
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: BackButton(color: Theme.of(context).appBarTheme.foregroundColor),
              title: Text(
                "Deck Details",
                style: TextStyle(color: Theme.of(context).appBarTheme.foregroundColor, fontWeight: FontWeight.bold, fontSize: 16),
              ),
              actions: [
                if (cards.isNotEmpty)
                  IconButton(
                    icon: Icon(Icons.checklist_rounded, color: Theme.of(context).appBarTheme.foregroundColor),
                    onPressed: onToggleSelectionMode,
                    tooltip: "Select Cards",
                  ),
              ],
            ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark ? Colors.white12 : const Color(0xFF8B4EFF).withValues(alpha: 0.25),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark ? Colors.black45 : const Color(0xFF8B4EFF).withValues(alpha: 0.12),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: _brandGradient,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF8B4EFF).withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        firstLetter,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 28,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          deck.name,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                            letterSpacing: -0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          deck.subject,
                          style: TextStyle(
                            color: isDark ? Colors.white70 : Colors.grey.shade600,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF8B4EFF).withValues(alpha: 0.15) : const Color(0xFFF4F6FF),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            "${deck.cardCount} card${deck.cardCount == 1 ? '' : 's'}",
                            style: TextStyle(
                              color: isDark ? const Color(0xFFB48AFF) : const Color(0xFF5A6DFF),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: onSettings,
                    icon: Icon(
                      Icons.settings_rounded, 
                      color: isDark ? Colors.white38 : Colors.grey.shade400,
                      size: 26,
                    ),
                    tooltip: 'Deck Settings',
                  ),
                ],
              ),
            ),

            Expanded(
              child: CustomScrollView(
                controller: scrollController,
                physics: const BouncingScrollPhysics(),
                slivers: [
                  AnimatedBuilder(
                    animation: expandAnimation,
                    builder: (context, child) {
                      return SliverPersistentHeader(
                        pinned: true,
                        delegate: _DeckActionsHeaderDelegate(
                          actionsHeight: actionsHeight,
                          expandProgress: expandAnimation.value,
                          cardCount: cards.length,
                          actionButtons: _buildActionButtons(context, canReview, canQuiz, hasFlagged, flaggedCount),
                          onExpand: () {
                            if (!actionsExpandController.isAnimating && !actionsExpandController.isCompleted) {
                              HapticFeedback.selectionClick();
                              actionsExpandController.forward();
                            }
                          },
                          onCollapse: () {
                            if (!actionsExpandController.isAnimating && actionsExpandController.value > 0) {
                              HapticFeedback.selectionClick();
                              actionsExpandController.reverse();
                            }
                          },
                        ),
                      );
                    },
                  ),

                  if (isLoading)
                    const SliverFillRemaining(
                      child: Center(
                        child: CircularProgressIndicator(color: Color(0xFF8B4EFF)),
                      ),
                    )
                  else if (cards.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _buildEmptyState(context, isDark),
                    )
                  else
                    _buildSliverCardsList(context, isDark),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: SafeArea(
        child: FloatingActionButton.extended(
          onPressed: onAddCard,
          backgroundColor: isDark ? const Color(0xFF8B4EFF) : const Color(0xFF1E1E2C),
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text(
            "Add Card",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, bool canReview, bool canQuiz, bool hasFlagged, int flaggedCount) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Opacity(
            opacity: canReview ? 1.0 : 0.5,
            child: Container(
              height: 60,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: _brandGradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  if (canReview)
                    BoxShadow(color: const Color(0xFF8B4EFF).withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 8)),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: canReview ? onReview : () => onDisabledAction("Add some cards first to start a review."),
                  borderRadius: BorderRadius.circular(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 28),
                      SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          "Study Entire Deck",
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18, letterSpacing: 0.5),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          if (hasFlagged) ...[
            const SizedBox(height: 12),
            Container(
              height: 52,
              width: double.infinity,
              decoration: BoxDecoration(
                color: isDark ? Colors.red.withValues(alpha: 0.1) : Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? Colors.red.withValues(alpha: 0.3) : Colors.red.shade100, width: 1.5),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onFlaggedReview,
                  borderRadius: BorderRadius.circular(12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.flag_rounded, color: isDark ? Colors.redAccent.shade200 : Colors.redAccent, size: 20),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          "Focus Weaknesses ($flaggedCount Card${flaggedCount == 1 ? '' : 's'})",
                          style: TextStyle(color: isDark ? Colors.redAccent.shade200 : Colors.redAccent, fontWeight: FontWeight.w700, fontSize: 15),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ] else ...[
            const SizedBox(height: 16),
          ],

          Row(
            children: [
              Expanded(child: _buildToolButton(context, Icons.quiz_rounded, "Quiz", const Color(0xFFFF9100), canQuiz, onQuiz, "You need at least 4 cards to take a quiz.")),
              const SizedBox(width: 12),
              Expanded(child: _buildToolButton(context, Icons.auto_awesome_rounded, "AI Tutor", const Color(0xFFE841A1), canReview, onAITutor, "Add cards to chat with the tutor.")),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildToolButton(BuildContext context, IconData icon, String label, Color color, bool canAct, VoidCallback action, String disabledMsg) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Opacity(
      opacity: canAct ? 1.0 : 0.5,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: canAct ? action : () => onDisabledAction(disabledMsg),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: 76,
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade300, width: 1.5),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: Text(
                    label,
                    style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: 12, fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(color: isDark ? const Color(0xFF1A1128) : const Color(0xFFF4F6FF), borderRadius: BorderRadius.circular(24)),
          child: Icon(Icons.style_outlined, size: 40, color: isDark ? const Color(0xFFB48AFF) : const Color(0xFF5A6DFF)),
        ),
        const SizedBox(height: 20, width: double.infinity),
        Text(
          "This deck is empty",
          style: TextStyle(fontSize: 20, color: Theme.of(context).textTheme.bodyLarge?.color, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text(
          "Add your first card to start studying!",
          style: TextStyle(color: isDark ? Colors.white70 : Colors.grey.shade600, fontSize: 15),
        ),
      ],
    );
  }

  Widget _buildSliverCardsList(BuildContext context, bool isDark) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      sliver: SliverReorderableList(
        itemCount: cards.length,
        onReorder: onReorderCards,
        itemBuilder: (context, index) {
          final card = cards[index];

          return TweenAnimationBuilder<double>(
            key: ValueKey(card.id), // 🔥 Providing a unique key is MANDATORY for reordering to work
            tween: Tween(begin: 0.0, end: 1.0),
            duration: Duration(milliseconds: 400 + (index * 50).clamp(0, 600)),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Transform.translate(offset: Offset(0, 30 * (1 - value)), child: Opacity(opacity: value, child: child));
            },
            child: GestureDetector(
              onLongPress: () {
                if (!isSelectionMode) {
                  onToggleSelectionMode();
                  onToggleCardSelection(card.id);
                }
              },
              onTap: () {
                if (isSelectionMode) onToggleCardSelection(card.id);
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: selectedCards.contains(card.id) 
                      ? (isDark ? Colors.blue.withValues(alpha: 0.15) : Colors.blue.shade50) 
                      : Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: selectedCards.contains(card.id)
                      ? Border.all(color: Colors.blueAccent, width: 2)
                      : (isDark ? Border.all(color: Colors.white.withValues(alpha: 0.05), width: 1) : null),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04), blurRadius: 15, offset: const Offset(0, 5))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (card.isFlagged)
                                Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(color: isDark ? Colors.red.withValues(alpha: 0.15) : Colors.red.shade50, shape: BoxShape.circle),
                                  child: Icon(Icons.flag_rounded, color: isDark ? Colors.redAccent.shade200 : Colors.redAccent, size: 14),
                                )
                              else if (card.isMastered)
                                Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(color: isDark ? Colors.green.withValues(alpha: 0.15) : Colors.green.shade50, shape: BoxShape.circle),
                                  child: Icon(Icons.check_rounded, color: isDark ? Colors.greenAccent.shade400 : Colors.green, size: 14),
                                ),
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(color: isDark ? const Color(0xFF8B4EFF).withValues(alpha: 0.1) : const Color(0xFFF4F6FF), borderRadius: BorderRadius.circular(12)),
                                  child: Text(
                                    "#${index + 1}",
                                    style: TextStyle(color: isDark ? const Color(0xFFB48AFF) : const Color(0xFF5A6DFF), fontSize: 11, fontWeight: FontWeight.w900),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isSelectionMode)
                              SizedBox(
                                width: 24,
                                height: 24,
                                child: Checkbox(
                                  value: selectedCards.contains(card.id),
                                  onChanged: (_) => onToggleCardSelection(card.id),
                                  activeColor: Colors.blueAccent,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                ),
                              )
                            else ...[
                              IconButton(
                                onPressed: () => onEditCard(card),
                                icon: Icon(Icons.edit_rounded, color: isDark ? Colors.white54 : Colors.black45, size: 20),
                                padding: const EdgeInsets.all(8),
                                constraints: const BoxConstraints(),
                              ),
                              const SizedBox(width: 4),
                              IconButton(
                                onPressed: () => onDeleteCard(card.id),
                                icon: Icon(Icons.delete_rounded, color: isDark ? Colors.redAccent.shade200 : Colors.redAccent, size: 20),
                                padding: const EdgeInsets.all(8),
                                constraints: const BoxConstraints(),
                              ),
                              const SizedBox(width: 4),
                              ReorderableDragStartListener(
                                index: index,
                                child: Icon(Icons.drag_handle_rounded, color: isDark ? Colors.white38 : Colors.black38, size: 20),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text("FRONT", style: TextStyle(color: isDark ? Colors.white54 : Colors.grey, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                    const SizedBox(height: 4),
                    Text(card.question, style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: 16, fontWeight: FontWeight.w600)),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Divider(height: 1, thickness: 1, color: isDark ? Colors.white12 : const Color(0xFFF0F0F0)),
                    ),
                    Text("BACK", style: TextStyle(color: isDark ? Colors.white54 : Colors.grey, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                    const SizedBox(height: 4),
                    Text(card.answer, style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: 15)),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DeckActionsHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double actionsHeight;
  final double expandProgress;
  final int cardCount;
  final Widget actionButtons;
  final VoidCallback onExpand;
  final VoidCallback onCollapse;

  _DeckActionsHeaderDelegate({
    required this.actionsHeight,
    required this.expandProgress,
    required this.cardCount,
    required this.actionButtons,
    required this.onExpand,
    required this.onCollapse,
  });

  @override
  double get maxExtent => actionsHeight + 64.0;

  @override
  double get minExtent => 64.0 + (actionsHeight * expandProgress);

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return ClipRect(
      child: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Stack(
          children: [
            Positioned(bottom: 64.0, left: 0, right: 0, height: actionsHeight, child: actionButtons),
            Positioned(
              bottom: 0, left: 0, right: 0, height: 64.0,
              child: GestureDetector(
                onVerticalDragUpdate: (details) {
                  if (details.delta.dy > 2) onExpand();
                  else if (details.delta.dy < -2) onCollapse();
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    boxShadow: (overlapsContent || expandProgress > 0)
                        ? [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.05), blurRadius: 10, offset: const Offset(0, 4))]
                        : [],
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(margin: const EdgeInsets.only(bottom: 8, top: 4), width: 36, height: 4, decoration: BoxDecoration(color: isDark ? Colors.white38 : Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
                      Row(
                        children: [
                          Text("Card List", style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: 18, fontWeight: FontWeight.w800)),
                          const Spacer(),
                          Text("$cardCount Total", style: TextStyle(color: isDark ? Colors.white54 : Colors.grey, fontSize: 14, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _DeckActionsHeaderDelegate oldDelegate) {
    return oldDelegate.actionsHeight != actionsHeight || oldDelegate.expandProgress != expandProgress || oldDelegate.cardCount != cardCount;
  }
}