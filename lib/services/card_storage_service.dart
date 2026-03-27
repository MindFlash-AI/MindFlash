import 'package:shared_preferences/shared_preferences.dart';
import '../models/card_model.dart';

abstract class ICardStorageService {
  Future<List<Flashcard>> getAllCards();
  Future<List<Flashcard>> getCardsForDeck(String deckId);
  Future<void> addCard(Flashcard card);
  Future<void> addCards(List<Flashcard> cards);
  Future<void> updateCard(Flashcard updatedCard);
  Future<void> deleteCard(String id);
}

class CardStorageService implements ICardStorageService {
  static const String _cardsKey = 'cards';

  // FIX 1: Cache the SharedPreferences instance — same reasoning as
  // DeckStorageService. Avoids a method-channel round-trip on every call.
  SharedPreferences? _prefs;

  Future<SharedPreferences> _getPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  @override
  Future<List<Flashcard>> getAllCards() async {
    final prefs = await _getPrefs();
    final List<String>? cardStrings = prefs.getStringList(_cardsKey);
    if (cardStrings == null) return [];
    return cardStrings.map((str) => Flashcard.fromJson(str)).toList();
  }

  @override
  Future<List<Flashcard>> getCardsForDeck(String deckId) async {
    final allCards = await getAllCards();
    return allCards.where((card) => card.deckId == deckId).toList();
  }

  Future<void> _saveCards(List<Flashcard> cards) async {
    final prefs = await _getPrefs();
    await prefs.setStringList(
      _cardsKey,
      cards.map((card) => card.toJson()).toList(),
    );
  }

  @override
  Future<void> addCard(Flashcard card) async {
    final cards = await getAllCards();
    cards.add(card);
    await _saveCards(cards);
  }

  // FIX 2: Bulk insert — 1 read + 1 write regardless of list size.
  // The old AI generation loop called addCard() N times: N reads + N writes.
  @override
  Future<void> addCards(List<Flashcard> newCards) async {
    if (newCards.isEmpty) return;
    final cards = await getAllCards();
    cards.addAll(newCards);
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