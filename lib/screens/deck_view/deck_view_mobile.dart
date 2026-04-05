import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/deck_model.dart';
import '../../models/card_model.dart';
import 'widgets/deck_info_card.dart';
import 'widgets/deck_action_buttons.dart';
import 'widgets/flashcard_list_item.dart';

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
            DeckInfoCard(
              deck: deck,
              onSettings: onSettings,
              brandGradient: _brandGradient,
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
                          actionButtons: DeckActionButtons(
                            canReview: canReview,
                            canQuiz: canQuiz,
                            hasFlagged: hasFlagged,
                            flaggedCount: flaggedCount,
                            onReview: onReview,
                            onFlaggedReview: onFlaggedReview,
                            onQuiz: onQuiz,
                            onAITutor: onAITutor,
                            onDisabledAction: onDisabledAction,
                            brandGradient: _brandGradient,
                          ),
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

          return FlashcardListItem(
            key: ValueKey(card.id),
            card: card,
            index: index,
            isSelectionMode: isSelectionMode,
            isSelected: selectedCards.contains(card.id),
            onEdit: onEditCard,
            onDelete: onDeleteCard,
            onToggleSelection: onToggleSelectionMode,
            onSelect: () => onToggleCardSelection(card.id),
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
