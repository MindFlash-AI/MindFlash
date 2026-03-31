import 'package:shared_preferences/shared_preferences.dart';
import '../models/card_model.dart';

class CardStorageService {
  static const String _cardsKey = 'flashcards_v2';
  
  SharedPreferences? _prefs;

  Future<SharedPreferences> _getPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  // --- Core CRUD Operations ---

  Future<List<Flashcard>> getAllCards() async {
    final prefs = await _getPrefs();
    final List<String>? cardStrings = prefs.getStringList(_cardsKey);
    if (cardStrings == null) return [];
    return cardStrings.map((str) => Flashcard.fromJson(str)).toList();
  }

  Future<void> _saveCards(List<Flashcard> cards) async {
    final prefs = await _getPrefs();
    await prefs.setStringList(
      _cardsKey,
      cards.map((card) => card.toJson()).toList(),
    );
  }

  Future<void> addCard(Flashcard card) async {
    final allCards = await getAllCards();
    allCards.add(card);
    await _saveCards(allCards);
  }

  Future<void> addCards(List<Flashcard> cards) async {
    final allCards = await getAllCards();
    allCards.addAll(cards);
    await _saveCards(allCards);
  }

  Future<void> updateCard(Flashcard updatedCard) async {
    final allCards = await getAllCards();
    final index = allCards.indexWhere((c) => c.id == updatedCard.id);
    if (index != -1) {
      allCards[index] = updatedCard;
      await _saveCards(allCards);
    }
  }

  Future<void> deleteCard(String cardId) async {
    final allCards = await getAllCards();
    allCards.removeWhere((c) => c.id == cardId);
    await _saveCards(allCards);
  }

  // --- Bulk Operations (For Deck Settings) ---

  Future<void> deleteCardsByDeck(String deckId) async {
    final allCards = await getAllCards();
    allCards.removeWhere((c) => c.deckId == deckId);
    await _saveCards(allCards);
  }

  Future<void> resetStatsForDeck(String deckId) async {
    final allCards = await getAllCards();
    for (var i = 0; i < allCards.length; i++) {
      if (allCards[i].deckId == deckId) {
        allCards[i].isMastered = false;
        allCards[i].isFlagged = false;
        allCards[i].repetitions = 0;
        allCards[i].easeFactor = 2.5;
        allCards[i].interval = 0;
        allCards[i].nextReviewDate = DateTime.now();
        allCards[i].lastScore = null;
      }
    }
    await _saveCards(allCards);
  }

  // --- Filtering Operations ---

  Future<List<Flashcard>> getCardsForDeck(String deckId) async {
    final allCards = await getAllCards();
    return allCards.where((card) => card.deckId == deckId).toList();
  }

  Future<List<Flashcard>> getDueCardsForDeck(String deckId) async {
    final deckCards = await getCardsForDeck(deckId);
    final now = DateTime.now();
    
    // Returns cards where the review date is today or in the past
    return deckCards.where((card) => 
        card.nextReviewDate.isBefore(now) || 
        card.nextReviewDate.isAtSameMomentAs(now)
    ).toList();
  }
}