import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import '../models/deck_model.dart';
import '../models/card_model.dart';
import 'deck_storage_service.dart';
import 'card_storage_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AIResponse {
  final String message;
  final Deck? generatedDeck;
  final Deck? editedDeck;

  const AIResponse({required this.message, this.generatedDeck, this.editedDeck});
}

class AIService {
  // Reuse a single http.Client across calls instead of creating a new TCP
  // connection on every request.
  static final http.Client _httpClient = http.Client();
  static const _uuid = Uuid();

  final DeckStorageService _deckStorage;
  final CardStorageService _cardStorage;

  // Allow injection for easier testing; fall back to real instances.
  AIService({
    DeckStorageService? deckStorage,
    CardStorageService? cardStorage,
  })  : _deckStorage = deckStorage ?? DeckStorageService(),
        _cardStorage = cardStorage ?? CardStorageService();

  // Lazily read the URL once instead of on every call.
  static final String _backendUrl = dotenv.env['BACKEND_URL']!;

  Future<AIResponse> processInput({
    String? text,
    String? fileText,
    String? fileName,
  }) async {
    // OPTIMIZATION 1: Run both storage reads in parallel instead of sequentially.
    // Previously: getDecks() finished → getAllCards() started → both awaited one-by-one.
    // Now both SharedPreferences reads fire simultaneously.
    final results = await Future.wait([
      _deckStorage.getDecks(),
      _cardStorage.getAllCards(),
    ]);

    final List<Deck> decks = results[0] as List<Deck>;
    final List<Flashcard> allCards = results[1] as List<Flashcard>;

    final String userDataContext = _buildUserContext(decks, allCards);

    final response = await _httpClient.post(
      Uri.parse(_backendUrl),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'prompt': text,
        'fileText': fileText,
        'fileName': fileName,
        'userContext': userDataContext,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(_parseErrorMessage(response));
    }

    final Map<String, dynamic> data =
        jsonDecode(response.body) as Map<String, dynamic>;

    final String action = (data['action'] as String?) ?? 'chat';
    final String reply = (data['reply'] as String?) ?? 'I processed your request.';

    Deck? newDeck;
    Deck? editedDeck;

    if (action == 'create_deck') {
      newDeck = await _handleCreateDeck(data, fileName);
    } else if (action == 'edit_deck') {
      // OPTIMIZATION 4: pass the already-fetched decks list so we don't
      // call getDecks() a second time inside the handler.
      editedDeck = await _handleEditDeck(data, decks);
    }

    return AIResponse(message: reply, generatedDeck: newDeck, editedDeck: editedDeck);
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  String _buildUserContext(List<Deck> decks, List<Flashcard> allCards) {
    if (decks.isEmpty) return 'The user currently has no saved decks.';

    // OPTIMIZATION 2a: group cards by deckId once with a Map (O(n))
    // instead of calling allCards.where(…) inside the loop (O(n²)).
    final Map<String, List<Flashcard>> cardsByDeck = {};
    for (final card in allCards) {
      cardsByDeck.putIfAbsent(card.deckId, () => []).add(card);
    }

    // OPTIMIZATION 2b: StringBuffer avoids repeated String heap allocations
    // that += causes inside a loop.
    final buffer = StringBuffer(
      'The user currently has the following study decks saved in their library:\n',
    );

    for (final deck in decks) {
      final deckCards = cardsByDeck[deck.id] ?? [];
      buffer.write(
        '- Deck Name: \'${deck.name}\' '
        '(Subject: ${deck.subject}, ID: ${deck.id}). '
        'It contains ${deckCards.length} cards.\n',
      );
      if (deckCards.isNotEmpty) {
        final first = deckCards.first;
        buffer.write(
          '  Examples: Q: \'${first.question}\' -> A: \'${first.answer}\'\n',
        );
      }
    }

    return buffer.toString();
  }

  Future<Deck?> _handleCreateDeck(
    Map<String, dynamic> data,
    String? fileName,
  ) async {
    final List<dynamic>? cardsData = data['cards'] as List<dynamic>?;
    if (cardsData == null || cardsData.isEmpty) return null;

    final newDeck = Deck(
      id: _uuid.v4(),
      name: (data['deckName'] as String?) ??
          (fileName != null ? 'Notes from $fileName' : 'AI Generated Deck'),
      subject: (data['subject'] as String?) ?? 'Generated Study Material',
      cardCount: cardsData.length,
    );

    // Build all Flashcard objects first (pure CPU, no I/O).
    final cards = cardsData.map((cardData) {
      return Flashcard(
        id: _uuid.v4(),
        deckId: newDeck.id,
        question: (cardData['q'] as Object).toString(),
        answer: (cardData['a'] as Object).toString(),
      );
    }).toList();

    // OPTIMIZATION 3: write the deck and all cards concurrently.
    // Previously every addCard() was awaited individually → N sequential writes.
    // Now: 1 deck write + 1 bulk card write, both in parallel.
    // Requires adding addCards() to CardStorageService — see companion diff.
    await Future.wait([
      _deckStorage.addDeck(newDeck),
      _cardStorage.addCards(cards),
    ]);

    return newDeck;
  }

  Future<Deck?> _handleEditDeck(
    Map<String, dynamic> data,
    List<Deck> decks,
  ) async {
    final String? targetId = data['targetDeckId'] as String?;
    final List<dynamic>? cardsData = data['cards'] as List<dynamic>?;

    if (targetId == null || cardsData == null || cardsData.isEmpty) return null;

    final int index = decks.indexWhere((d) => d.id == targetId);
    if (index == -1) return null;

    final Deck editedDeck = decks[index];

    final newCards = cardsData.map((cardData) {
      return Flashcard(
        id: _uuid.v4(),
        deckId: editedDeck.id,
        question: (cardData['q'] as Object).toString(),
        answer: (cardData['a'] as Object).toString(),
      );
    }).toList();

    editedDeck.cardCount += newCards.length;

    // OPTIMIZATION 3 (same pattern): bulk write + deck update in parallel.
    await Future.wait([
      _cardStorage.addCards(newCards),
      _deckStorage.updateDeck(editedDeck),
    ]);

    return editedDeck;
  }

  String _parseErrorMessage(http.Response response) {
    try {
      final errorData = jsonDecode(response.body) as Map<String, dynamic>;
      final details = errorData['details']?.toString() ?? '';
      if (details.contains('503') || details.contains('high demand')) {
        return 'The AI service is currently experiencing high demand. '
            'Please try again in a few moments.';
      }
      final error = errorData['error']?.toString();
      if (error != null) return 'Server error ${response.statusCode}\nError: $error';
      if (details.isNotEmpty) return 'Server error ${response.statusCode}\nDetails: $details';
    } catch (_) {
      // fall through to generic message
    }
    return 'Server error ${response.statusCode}\nBody: ${response.body}';
  }
}