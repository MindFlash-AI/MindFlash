import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/deck_model.dart';
import '../models/card_model.dart';
import 'deck_storage_service.dart';
import 'card_storage_service.dart';

class AIResponse {
  final String message;
  final Deck? generatedDeck;
  final Deck? editedDeck;

  const AIResponse({required this.message, this.generatedDeck, this.editedDeck});
}

class AIService {
  static final http.Client _httpClient = http.Client();
  static const _uuid = Uuid();

  final DeckStorageService _deckStorage;
  final CardStorageService _cardStorage;

  AIService({
    DeckStorageService? deckStorage,
    CardStorageService? cardStorage,
  })  : _deckStorage = deckStorage ?? DeckStorageService(),
        _cardStorage = cardStorage ?? CardStorageService();

  static final String _backendUrl = dotenv.env['BACKEND_URL']!;

  Future<Map<String, String>> _getSecureHeaders() async {
    final appCheckToken = await FirebaseAppCheck.instance.getToken();
    final user = FirebaseAuth.instance.currentUser;
    final idToken = await user?.getIdToken();

    return {
      'Content-Type': 'application/json',
      'X-Firebase-AppCheck': appCheckToken ?? '',
      'Authorization': 'Bearer ${idToken ?? ''}', 
    };
  }

  Future<AIResponse> processInput({
    String? text,
    String? fileText,
    String? fileName,
  }) async {
    final results = await Future.wait([
      _deckStorage.getDecks(),
      _cardStorage.getAllCards(),
    ]);

    final List<Deck> decks = results[0] as List<Deck>;
    final List<Flashcard> allCards = results[1] as List<Flashcard>;

    final String userDataContext = _buildUserContext(decks, allCards);
    final headers = await _getSecureHeaders();

    final response = await _httpClient.post(
      Uri.parse(_backendUrl),
      headers: headers,
      body: jsonEncode({
        'prompt': text,
        'fileText': fileText,
        'fileName': fileName,
        'userContext': userDataContext,
        'isChat': false, // APPROACH C: Indicates this is a generation (Costs 3)
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(_parseErrorMessage(response));
    }

    final Map<String, dynamic> data = jsonDecode(response.body) as Map<String, dynamic>;
    final String action = (data['action'] as String?) ?? 'chat';
    final String reply = (data['reply'] as String?) ?? 'I processed your request.';

    Deck? newDeck;
    Deck? editedDeck;

    if (action == 'create_deck') {
      newDeck = await _handleCreateDeck(data, fileName);
    } else if (action == 'edit_deck') {
      editedDeck = await _handleEditDeck(data, decks);
    }

    return AIResponse(message: reply, generatedDeck: newDeck, editedDeck: editedDeck);
  }

  Future<AIResponse> processTutorChat({
    required String text,
    required Deck deck,
    required List<Flashcard> cards,
  }) async {
    final String deckContext = "The user is studying the deck '${deck.name}' (Subject: ${deck.subject}).\n"
        "Here are the flashcards currently in this deck:\n" +
        cards.map((c) => "- Q: '${c.question}' -> A: '${c.answer}'").join('\n');

    final headers = await _getSecureHeaders();

    final response = await _httpClient.post(
      Uri.parse(_backendUrl),
      headers: headers,
      body: jsonEncode({
        'prompt': "CRITICAL RULE: You are ONLY a study tutor. You are STRICTLY FORBIDDEN from creating, updating, editing, or deleting any flashcards. ALWAYS respond with the action 'chat' and act as a conversational tutor helping the user master the current deck.\n\nUser Message: $text",
        'userContext': deckContext,
        'isChat': true, // APPROACH C: Indicates this is a chat (Costs 1)
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(_parseErrorMessage(response));
    }

    final Map<String, dynamic> data = jsonDecode(response.body) as Map<String, dynamic>;
    final String reply = (data['reply'] as String?) ?? 'I processed your request.';

    return AIResponse(message: reply);
  }

  // --- Private Helpers ---

  String _buildUserContext(List<Deck> decks, List<Flashcard> allCards) {
    if (decks.isEmpty) return 'The user currently has no saved decks.';

    final Map<String, List<Flashcard>> cardsByDeck = {};
    for (final card in allCards) {
      cardsByDeck.putIfAbsent(card.deckId, () => []).add(card);
    }

    final buffer = StringBuffer('The user currently has the following study decks saved in their library:\n');
    for (final deck in decks) {
      final deckCards = cardsByDeck[deck.id] ?? [];
      buffer.write('- Deck Name: \'${deck.name}\' (Subject: ${deck.subject}, ID: ${deck.id}). It contains ${deckCards.length} cards.\n');
      if (deckCards.isNotEmpty) {
        final first = deckCards.first;
        buffer.write('  Examples: Q: \'${first.question}\' -> A: \'${first.answer}\'\n');
      }
    }
    return buffer.toString();
  }

  Future<Deck?> _handleCreateDeck(Map<String, dynamic> data, String? fileName) async {
    final List<dynamic>? cardsData = data['cards'] as List<dynamic>?;
    if (cardsData == null || cardsData.isEmpty) return null;

    final newDeck = Deck(
      id: _uuid.v4(),
      name: (data['deckName'] as String?) ?? (fileName != null ? 'Notes from $fileName' : 'AI Generated Deck'),
      subject: (data['subject'] as String?) ?? 'Generated Study Material',
      cardCount: cardsData.length,
    );

    final cards = cardsData.map((cardData) {
      return Flashcard(
        id: _uuid.v4(),
        deckId: newDeck.id,
        question: (cardData['q'] as Object).toString(),
        answer: (cardData['a'] as Object).toString(),
      );
    }).toList();

    await Future.wait([
      _deckStorage.addDeck(newDeck),
      _cardStorage.addCards(cards),
    ]);

    return newDeck;
  }

  Future<Deck?> _handleEditDeck(Map<String, dynamic> data, List<Deck> decks) async {
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

    await Future.wait([
      _cardStorage.addCards(newCards),
      _deckStorage.updateDeck(editedDeck),
    ]);

    return editedDeck;
  }

  String _parseErrorMessage(http.Response response) {
    if (response.statusCode == 403) {
      // Decode the precise message from the backend (e.g. "Generating a deck costs 3 energy.")
      try {
        final data = jsonDecode(response.body);
        return data['error'] ?? 'Out of energy! Please watch an ad to recharge.';
      } catch (_) {
        return 'Out of energy! Please watch an ad to recharge.';
      }
    }
    
    try {
      final errorData = jsonDecode(response.body) as Map<String, dynamic>;
      final details = errorData['details']?.toString() ?? '';
      if (details.contains('503') || details.contains('high demand')) {
        return 'The AI service is currently experiencing high demand. Please try again in a few moments.';
      }
      final error = errorData['error']?.toString();
      if (error != null) return 'Server error ${response.statusCode}\nError: $error';
      if (details.isNotEmpty) return 'Server error ${response.statusCode}\nDetails: $details';
    } catch (_) {}
    return 'Server error ${response.statusCode}\nBody: ${response.body}';
  }
}