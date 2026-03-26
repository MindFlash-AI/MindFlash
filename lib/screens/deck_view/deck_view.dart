import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/deck_model.dart';
import '../../models/card_model.dart';
import '../../services/card_storage_service.dart';
import '../../services/deck_storage_service.dart';

import '../../widgets/create_card_dialog.dart';
import '../../widgets/edit_card_dialog.dart';

import '../review/review_screen.dart';
import '../quiz/quiz_screen.dart';
import '../chat/ai_chat_screen.dart';
import '../../services/quiz_creator.dart';

class DeckView extends StatefulWidget {
  final Deck deck;

  const DeckView({super.key, required this.deck});

  @override
  State<DeckView> createState() => _DeckViewState();
}

class _DeckViewState extends State<DeckView> with TickerProviderStateMixin {
  final CardStorageService _cardStorageService = CardStorageService();
  final DeckStorageService _deckStorageService = DeckStorageService();
  final ScrollController _scrollController = ScrollController();

  late AnimationController _actionsExpandController;
  late Animation<double> _expandAnimation;

  List<Flashcard> _cards = [];
  bool _isLoading = true;

  final LinearGradient _brandGradient = const LinearGradient(
    colors: [Color(0xFF8B4EFF), Color(0xFFE841A1)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  void initState() {
    super.initState();

    _actionsExpandController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _expandAnimation = CurvedAnimation(
      parent: _actionsExpandController,
      curve: Curves.easeOutCubic,
    );

    _scrollController.addListener(() {
      if (_scrollController.offset <= 0 && _actionsExpandController.value > 0) {
        _actionsExpandController.value = 0.0;
      }
    });

    _loadCards();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _actionsExpandController.dispose();
    super.dispose();
  }

  Future<void> _loadCards() async {
    final cards = await _cardStorageService.getCardsForDeck(widget.deck.id);
    setState(() {
      _cards = cards;
      _isLoading = false;
    });
  }

  void _onCardCreated(Flashcard card) async {
    await _cardStorageService.addCard(card);
    setState(() {
      widget.deck.cardCount += 1;
    });
    await _deckStorageService.updateDeck(widget.deck);
    _loadCards();
  }

  Future<void> _confirmDeleteCard(String cardId) async {
    HapticFeedback.heavyImpact();
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "Delete Card?",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text("Are you sure? This action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade50,
              foregroundColor: Colors.red,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              "Delete",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _cardStorageService.deleteCard(cardId);
      setState(() {
        if (widget.deck.cardCount > 0) widget.deck.cardCount -= 1;
      });
      await _deckStorageService.updateDeck(widget.deck);
      _loadCards();
    }
  }

  void _startReview() async {
    HapticFeedback.lightImpact();
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ReviewScreen(deck: widget.deck, cards: _cards, isShuffleOn: false),
      ),
    );
    _loadCards();
  }

  void _startFlaggedReview() async {
    HapticFeedback.lightImpact();
    final flaggedCards = _cards.where((c) => c.isFlagged).toList();
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReviewScreen(
          deck: widget.deck,
          cards: flaggedCards,
          isShuffleOn: false,
        ),
      ),
    );
    _loadCards();
  }

  void _startQuiz() {
    HapticFeedback.lightImpact();
    final quizQuestions = LocalQuizEngine.generateMCQ(_cards);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            QuizScreen(quiz: quizQuestions, deckTitle: widget.deck.name),
      ),
    );
  }

  void _openAITutor() {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AIChatScreen(deck: widget.deck, cards: _cards),
      ),
    );
  }

  void _showDisabledSnackBar(String message) {
    HapticFeedback.heavyImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.black87,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Widget _buildActionButtons(
    bool canReview,
    bool canQuiz,
    bool hasFlagged,
    int flaggedCount,
  ) {
    return Container(
      color: const Color(0xFFFDF9FF),
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
                    BoxShadow(
                      color: const Color(0xFF8B4EFF).withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: canReview
                      ? _startReview
                      : () => _showDisabledSnackBar(
                          "Add some cards first to start a review.",
                        ),
                  borderRadius: BorderRadius.circular(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(
                        Icons.play_circle_fill_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                      SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          "Study Entire Deck",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                            letterSpacing: 0.5,
                          ),
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
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade100, width: 1.5),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _startFlaggedReview,
                  borderRadius: BorderRadius.circular(12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.flag_rounded,
                        color: Colors.redAccent,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          "Focus Weaknesses ($flaggedCount Card${flaggedCount == 1 ? '' : 's'})",
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
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
              Expanded(
                child: _buildToolButton(
                  icon: Icons.quiz_rounded,
                  label: "Quiz",
                  color: const Color(0xFFFF9100),
                  isDisabled: !canQuiz,
                  onTap: () {
                    if (canQuiz)
                      _startQuiz();
                    else
                      _showDisabledSnackBar(
                        "You need at least 4 cards to take a quiz.",
                      );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildToolButton(
                  icon: Icons.auto_awesome_rounded,
                  label: "AI Tutor",
                  color: const Color(0xFFE841A1),
                  isDisabled: !canReview,
                  onTap: () {
                    if (canReview)
                      _openAITutor();
                    else
                      _showDisabledSnackBar(
                        "Add cards to chat with the tutor.",
                      );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String firstLetter = widget.deck.name.isNotEmpty
        ? widget.deck.name[0].toUpperCase()
        : "?";

    final bool canReview = _cards.isNotEmpty;
    final bool canQuiz = _cards.length >= 4;
    final int flaggedCount = _cards.where((c) => c.isFlagged).length;
    final bool hasFlagged = flaggedCount > 0;

    final double actionsHeight = hasFlagged ? 248.0 : 184.0;

    return Scaffold(
      backgroundColor: const Color(0xFFFDF9FF),
      appBar: AppBar(
        systemOverlayStyle: SystemUiOverlayStyle.dark.copyWith(
          statusBarColor: Colors.transparent,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.black87),
        title: const Text(
          "Deck Details",
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: const Color(0xFF8B4EFF).withOpacity(0.25),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF8B4EFF).withOpacity(0.12),
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
                          color: const Color(0xFF8B4EFF).withOpacity(0.3),
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
                          widget.deck.name,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Colors.black87,
                            letterSpacing: -0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.deck.subject,
                          style: TextStyle(
                            color: Colors.grey.shade600,
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
                            color: const Color(0xFFF4F6FF),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            "${widget.deck.cardCount} card${widget.deck.cardCount == 1 ? '' : 's'}",
                            style: const TextStyle(
                              color: Color(0xFF5A6DFF),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: CustomScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                slivers: [
                  AnimatedBuilder(
                    animation: _expandAnimation,
                    builder: (context, child) {
                      return SliverPersistentHeader(
                        pinned: true,
                        delegate: _DeckActionsHeaderDelegate(
                          actionsHeight: actionsHeight,
                          expandProgress: _expandAnimation.value,
                          cardCount: _cards.length,
                          actionButtons: _buildActionButtons(
                            canReview,
                            canQuiz,
                            hasFlagged,
                            flaggedCount,
                          ),
                          onExpand: () {
                            if (!_actionsExpandController.isAnimating &&
                                !_actionsExpandController.isCompleted) {
                              HapticFeedback.selectionClick();
                              _actionsExpandController.forward();
                            }
                          },
                          onCollapse: () {
                            if (!_actionsExpandController.isAnimating &&
                                _actionsExpandController.value > 0) {
                              HapticFeedback.selectionClick();
                              _actionsExpandController.reverse();
                            }
                          },
                        ),
                      );
                    },
                  ),

                  if (_isLoading)
                    const SliverFillRemaining(
                      child: Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF8B4EFF),
                        ),
                      ),
                    )
                  else if (_cards.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _buildEmptyState(),
                    )
                  else
                    _buildSliverCardsList(),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: SafeArea(
        child: FloatingActionButton.extended(
          onPressed: () {
            HapticFeedback.lightImpact();
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => CreateCardDialog(
                deckId: widget.deck.id,
                onCardCreated: _onCardCreated,
              ),
            );
          },
          backgroundColor: const Color(0xFF1E1E2C),
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text(
            "Add Card",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildToolButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    bool isActive = false,
    bool isDisabled = false,
  }) {
    return Opacity(
      opacity: isDisabled ? 0.5 : 1.0,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: 76,
            decoration: BoxDecoration(
              color: isActive ? color : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isActive ? color : Colors.grey.shade300,
                width: 1.5,
              ),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: color.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: isActive ? Colors.white : color, size: 24),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: Text(
                    label,
                    style: TextStyle(
                      color: isActive ? Colors.white : Colors.black87,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
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

  Widget _buildEmptyState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: const Color(0xFFF4F6FF),
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Icon(
            Icons.style_outlined,
            size: 40,
            color: Color(0xFF5A6DFF),
          ),
        ),
        const SizedBox(height: 20, width: double.infinity),
        const Text(
          "This deck is empty",
          style: TextStyle(
            fontSize: 20,
            color: Colors.black87,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Add your first card to start studying!",
          style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
        ),
      ],
    );
  }

  Widget _buildSliverCardsList() {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final card = _cards[index];

          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: Duration(milliseconds: 400 + (index * 100).clamp(0, 600)),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, 30 * (1 - value)),
                child: Opacity(opacity: value, child: child),
              );
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
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
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.flag_rounded,
                                  color: Colors.redAccent,
                                  size: 14,
                                ),
                              )
                            else if (card.isMastered)
                              Container(
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check_rounded,
                                  color: Colors.green,
                                  size: 14,
                                ),
                              ),
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF4F6FF),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  "#${index + 1}",
                                  style: const TextStyle(
                                    color: Color(0xFF5A6DFF),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                  ),
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
                          IconButton(
                            onPressed: () {
                              HapticFeedback.selectionClick();
                              showDialog(
                                context: context,
                                builder: (context) => EditCardDialog(
                                  card: card,
                                  onCardUpdated: (updatedCard) async {
                                    await _cardStorageService.updateCard(
                                      updatedCard,
                                    );
                                    _loadCards();
                                  },
                                ),
                              );
                            },
                            icon: const Icon(
                              Icons.edit_rounded,
                              color: Colors.black45,
                              size: 20,
                            ),
                            padding: const EdgeInsets.all(8),
                            constraints: const BoxConstraints(),
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            onPressed: () => _confirmDeleteCard(card.id),
                            icon: const Icon(
                              Icons.delete_rounded,
                              color: Colors.redAccent,
                              size: 20,
                            ),
                            padding: const EdgeInsets.all(8),
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  const Text(
                    "FRONT",
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    card.question,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(
                      height: 1,
                      thickness: 1,
                      color: Color(0xFFF0F0F0),
                    ),
                  ),

                  const Text(
                    "BACK",
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    card.answer,
                    style: const TextStyle(color: Colors.black87, fontSize: 15),
                  ),
                ],
              ),
            ),
          );
        }, childCount: _cards.length),
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
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return ClipRect(
      child: Container(
        color: const Color(0xFFFDF9FF),
        child: Stack(
          children: [
            Positioned(
              bottom: 64.0,
              left: 0,
              right: 0,
              height: actionsHeight,
              child: actionButtons,
            ),

            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 64.0,
              child: GestureDetector(
                onVerticalDragUpdate: (details) {
                  if (details.delta.dy > 2) {
                    onExpand();
                  } else if (details.delta.dy < -2) {
                    onCollapse();
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDF9FF),
                    boxShadow: (overlapsContent || expandProgress > 0)
                        ? [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : [],
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(bottom: 8, top: 4),
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Row(
                        children: [
                          const Text(
                            "Card List",
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            "$cardCount Total",
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
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
    return oldDelegate.actionsHeight != actionsHeight ||
        oldDelegate.expandProgress != expandProgress ||
        oldDelegate.cardCount != cardCount;
  }
}
