import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'deck_model.dart';
import 'card_model.dart';
import 'card_storage_service.dart';
import 'deck_storage_service.dart';
import 'create_card_dialog.dart';
import 'edit_card_dialog.dart';
import 'review.dart';
import 'quiz_creator.dart';
import 'quiz_screen.dart';

class DeckView extends StatefulWidget {
  final Deck deck;

  const DeckView({super.key, required this.deck});

  @override
  State<DeckView> createState() => _DeckViewState();
}

class _DeckViewState extends State<DeckView> {
  final CardStorageService _cardStorageService = CardStorageService();
  final DeckStorageService _deckStorageService = DeckStorageService();
  List<Flashcard> _cards = [];
  bool _isLoading = true;
  bool _isShuffleOn = false;

  final LinearGradient _brandGradient = const LinearGradient(
    colors: [Color(0xFF8B4EFF), Color(0xFFE841A1)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  final LinearGradient _quizGradient = const LinearGradient(
    colors: [Color(0xFFFF9100), Color(0xFFFF6D00)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  @override
  void initState() {
    super.initState();
    _loadCards();
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
        builder: (context) => ReviewScreen(
          deck: widget.deck,
          cards: _cards,
          isShuffleOn: _isShuffleOn,
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

  @override
  Widget build(BuildContext context) {
    String firstLetter = widget.deck.name.isNotEmpty
        ? widget.deck.name[0].toUpperCase()
        : "?";

    final bool canReview = _cards.isNotEmpty;
    final bool canQuiz = _cards.length >= 4;

    return Scaffold(
      backgroundColor: const Color(0xFFFDF9FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.black87),
        title: const Text(
          "Back",
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Row(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    gradient: _brandGradient,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF8B4EFF).withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      firstLetter,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 32,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.deck.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Colors.black87,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.deck.subject,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4F6FF),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "${widget.deck.cardCount} card${widget.deck.cardCount == 1 ? '' : 's'}",
                          style: const TextStyle(
                            color: Color(0xFF5A6DFF),
                            fontSize: 12,
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

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Opacity(
                        opacity: canReview ? 1.0 : 0.5,
                        child: Container(
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: _brandGradient,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              if (canReview)
                                BoxShadow(
                                  color: const Color(
                                    0xFF8B4EFF,
                                  ).withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: canReview ? _startReview : null,
                              borderRadius: BorderRadius.circular(16),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(
                                    Icons.play_arrow_rounded,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    "Review",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        height: 56,
                        decoration: BoxDecoration(
                          color: _isShuffleOn
                              ? const Color(0xFFF4F6FF)
                              : Colors.white,
                          border: Border.all(
                            color: _isShuffleOn
                                ? const Color(0xFFD6DFFF)
                                : Colors.grey.shade300,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() => _isShuffleOn = !_isShuffleOn);
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.shuffle_rounded,
                                  color: _isShuffleOn
                                      ? const Color(0xFF5A6DFF)
                                      : Colors.black54,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "Shuffle",
                                  style: TextStyle(
                                    color: _isShuffleOn
                                        ? const Color(0xFF5A6DFF)
                                        : Colors.black87,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Opacity(
                  opacity: canQuiz ? 1.0 : 0.5,
                  child: Container(
                    height: 56,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: _quizGradient,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        if (canQuiz)
                          BoxShadow(
                            color: const Color(0xFFFF9100).withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: canQuiz ? _startQuiz : null,
                        borderRadius: BorderRadius.circular(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.quiz_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              canQuiz
                                  ? "Take a Quiz"
                                  : "Need 4+ Cards for Quiz",
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Row(
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
                  "${_cards.length} Total",
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF8B4EFF)),
                  )
                : _cards.isEmpty
                ? _buildEmptyState()
                : _buildCardsList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
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

  Widget _buildCardsList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
      physics: const BouncingScrollPhysics(),
      itemCount: _cards.length,
      itemBuilder: (context, index) {
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
                    Container(
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
                      ),
                    ),
                    Row(
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
      },
    );
  }
}
