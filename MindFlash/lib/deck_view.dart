import 'package:flutter/material.dart';
import 'deck_model.dart';
import 'card_model.dart';
import 'card_storage_service.dart';
import 'deck_storage_service.dart'; 
import 'create_card_dialog.dart';
import 'edit_card_dialog.dart'; // Added Import
import 'review.dart';

class DeckView extends StatefulWidget {
  final Deck deck;

  const DeckView({super.key, required this.deck});

  @override
  State<DeckView> createState() => _DeckViewState();
}

class _DeckViewState extends State<DeckView> {
  final CardStorageService _cardStorageService = CardStorageService();
  final DeckStorageService _deckStorageService = DeckStorageService(); // Added service
  List<Flashcard> _cards = [];
  bool _isLoading = true;
  bool _isShuffleOn = false;

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
    // --- PERSIST THE UPDATED DECK COUNT ---
    await _deckStorageService.updateDeck(widget.deck);
    
    _loadCards();
  }

  void _deleteCard(String cardId) async {
    await _cardStorageService.deleteCard(cardId);
    setState(() {
      if (widget.deck.cardCount > 0) widget.deck.cardCount -= 1;
    });
    // --- PERSIST THE UPDATED DECK COUNT ---
    await _deckStorageService.updateDeck(widget.deck);
    
    _loadCards();
  }

  void _startReview() async {
    if (_cards.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Add some cards first to start reviewing!")),
      );
      return;
    }
    // Await added to reload if a card was edited during review
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

  @override
  Widget build(BuildContext context) {
    String firstLetter =
        widget.deck.name.isNotEmpty ? widget.deck.name[0].toUpperCase() : "?";

    return Scaffold(
      backgroundColor: const Color(0xFFFDF9FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        title: const Text(
          "Back",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Row(
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFA57A),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      firstLetter,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 32,
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
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E1E2C),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.deck.subject,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "${widget.deck.cardCount} card${widget.deck.cardCount == 1 ? '' : 's'}",
                        style: const TextStyle(
                          color: Color(0xFF5B4FE6),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    ],
                  ),
                )
              ],
            ),
          ),

          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF8B4EFF), Color(0xFFE841A1)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 55,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF7A40F2), Color(0xFF9830E8)],
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: _startReview,
                                borderRadius: BorderRadius.circular(16),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Icon(Icons.play_arrow_outlined, color: Colors.white),
                                    SizedBox(width: 8),
                                    Text(
                                      "Start Review",
                                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            height: 55,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3E8FF),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => setState(() => _isShuffleOn = !_isShuffleOn),
                                borderRadius: BorderRadius.circular(16),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.shuffle, color: _isShuffleOn ? const Color(0xFF7A40F2) : Colors.black87),
                                    const SizedBox(width: 8),
                                    Text(
                                      _isShuffleOn ? "Shuffle ON" : "Shuffle OFF",
                                      style: TextStyle(
                                        color: _isShuffleOn ? const Color(0xFF7A40F2) : Colors.black87, 
                                        fontWeight: FontWeight.bold, 
                                        fontSize: 15
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

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Text(
                      "Cards (${_cards.length})",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  Expanded(
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator(color: Colors.white))
                        : _cards.isEmpty
                            ? _buildEmptyState()
                            : _buildCardsList(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => CreateCardDialog(
              deckId: widget.deck.id,
              onCardCreated: _onCardCreated,
            ),
          );
        },
        backgroundColor: const Color(0xFF7A40F2),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Add Card", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            color: Colors.white24,
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Icon(Icons.add_photo_alternate_outlined, size: 36, color: Colors.white),
        ),
        const SizedBox(height: 20, width: double.infinity),
        const Text(
          "No Cards Yet",
          style: TextStyle(
            fontSize: 20,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          "Add your first card to start studying!",
          style: TextStyle(color: Colors.white70),
        ),
      ],
    );
  }

  Widget _buildCardsList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
      itemCount: _cards.length,
      itemBuilder: (context, index) {
        final card = _cards[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7A40F2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "#${index + 1}",
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Row(
                    children: [
                      // Edit Button implemented
                      InkWell(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) => EditCardDialog(
                              card: card,
                              onCardUpdated: (updatedCard) async {
                                await _cardStorageService.updateCard(updatedCard);
                                _loadCards();
                              },
                            ),
                          );
                        },
                        child: const Icon(Icons.edit_outlined, color: Colors.grey, size: 20),
                      ),
                      const SizedBox(width: 16),
                      InkWell(
                        onTap: () => _deleteCard(card.id),
                        child: const Icon(Icons.delete_outline, color: Colors.grey, size: 20),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F6FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "QUESTION",
                      style: TextStyle(color: Color(0xFF5A6DFF), fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(card.question, style: const TextStyle(color: Colors.black87, fontSize: 14)),
                    const SizedBox(height: 16),
              
                    const Text(
                      "ANSWER",
                      style: TextStyle(color: Color(0xFFC042E6), fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(card.answer, style: const TextStyle(color: Colors.black87, fontSize: 14)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}