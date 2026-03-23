import 'package:shared_preferences/shared_preferences.dart';
import '../../models/card_model.dart';

// SOLID: Dependency Inversion Principle
// We define an interface so the UI depends on the abstraction, not the implementation.
abstract class ICardStorageService {
  Future<List<Flashcard>> getAllCards();
  Future<List<Flashcard>> getCardsForDeck(String deckId);
  Future<void> addCard(Flashcard card);
  Future<void> updateCard(Flashcard updatedCard);
  Future<void> deleteCard(String id);
}

class CardStorageService implements ICardStorageService {
  static const String _cardsKey = 'cards';

  @override
  Future<List<Flashcard>> getAllCards() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? cardStrings = prefs.getStringList(_cardsKey);
    if (cardStrings == null) {
      return [];
    }
    return cardStrings.map((str) => Flashcard.fromJson(str)).toList();
  }

  @override
  Future<List<Flashcard>> getCardsForDeck(String deckId) async {
    final allCards = await getAllCards();
    return allCards.where((card) => card.deckId == deckId).toList();
  }

  Future<void> _saveCards(List<Flashcard> cards) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> cardStrings =
        cards.map((card) => card.toJson()).toList();
    await prefs.setStringList(_cardsKey, cardStrings);
  }

  @override
  Future<void> addCard(Flashcard card) async {
    final cards = await getAllCards();
    cards.add(card);
    await _saveCards(cards);
  }

  @override
  Future<void> updateCard(Flashcard updatedCard) async {
    final cards = await getAllCards();
    final index = cards.indexWhere((c) => c.id == updatedCard.id);
    if (index != -1) {
      cards[index] = updatedCard;
      await _saveCards(cards);
    }
  }

  @override
  Future<void> deleteCard(String id) async {
    final cards = await getAllCards();
    cards.removeWhere((card) => card.id == id);
    await _saveCards(cards);
  }
}