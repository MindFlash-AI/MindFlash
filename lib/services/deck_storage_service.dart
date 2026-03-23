import 'package:shared_preferences/shared_preferences.dart';
import '../models/deck_model.dart';

class DeckStorageService {
  static const String _decksKey = 'decks';

  Future<List<Deck>> getDecks() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? deckStrings = prefs.getStringList(_decksKey);
    if (deckStrings == null) {
      return [];
    }
    return deckStrings.map((str) => Deck.fromJson(str)).toList();
  }

  Future<void> _saveDecks(List<Deck> decks) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> deckStrings = decks
        .map((deck) => deck.toJson())
        .toList();
    await prefs.setStringList(_decksKey, deckStrings);
  }

  Future<void> addDeck(Deck deck) async {
    final decks = await getDecks();
    decks.add(deck);
    await _saveDecks(decks);
  }

  Future<void> deleteDeck(String id) async {
    final decks = await getDecks();
    decks.removeWhere((deck) => deck.id == id);
    await _saveDecks(decks);
  }

  Future<void> updateDeck(Deck updatedDeck) async {
    final decks = await getDecks();
    final index = decks.indexWhere((deck) => deck.id == updatedDeck.id);
    if (index != -1) {
      decks[index] = updatedDeck;
      await _saveDecks(decks);
    }
  }
}
