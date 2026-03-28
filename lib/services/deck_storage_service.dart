import 'package:shared_preferences/shared_preferences.dart';
import '../models/deck_model.dart';

class DeckStorageService {
  static const String _decksKey = 'decks';

  // FIX: Cache the SharedPreferences instance instead of calling getInstance()
  // on every method. getInstance() is async and goes through a method channel
  // call each time, even though Flutter's implementation is already a singleton.
  // One-time init via _prefs eliminates that overhead for every read/write.
  SharedPreferences? _prefs;

  Future<SharedPreferences> _getPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  Future<List<Deck>> getDecks() async {
    final prefs = await _getPrefs();
    final List<String>? deckStrings = prefs.getStringList(_decksKey);
    if (deckStrings == null) return [];
    return deckStrings.map((str) => Deck.fromJson(str)).toList();
  }

  Future<void> _saveDecks(List<Deck> decks) async {
    final prefs = await _getPrefs();
    await prefs.setStringList(
      _decksKey,
      decks.map((deck) => deck.toJson()).toList(),
    );
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