import 'package:shared_preferences/shared_preferences.dart';
import 'card_model.dart';

class CardStorageService {
  static const String _cardsKey = 'cards';

  Future<List<Flashcard>> getAllCards() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? cardStrings = prefs.getStringList(_cardsKey);
    if (cardStrings == null) {
      return [];
    }
    return cardStrings.map((str) => Flashcard.fromJson(str)).toList();
  }

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

  Future<void> addCard(Flashcard card) async {
    final cards = await getAllCards();
    cards.add(card);
    await _saveCards(cards);
  }

  Future<void> deleteCard(String id) async {
    final cards = await getAllCards();
    cards.removeWhere((card) => card.id == id);
    await _saveCards(cards);
  }
}