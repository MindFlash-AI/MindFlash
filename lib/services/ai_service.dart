import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
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

  // 🛡️ WEB FIX: Use 'const' for the environment variable
  static const String _backendUrl = String.fromEnvironment('BACKEND_URL');

  Future<Map<String, String>> _getSecureHeaders() async {
    final appCheckToken = await FirebaseAppCheck.instance.getToken();
    final user = FirebaseAuth.instance.currentUser;
    final idToken = await user?.getIdToken();

    return {
      'Content-Type': 'application/json',
      'X-Firebase-AppCheck': appCheckToken?.toString() ?? '',
      'Authorization': 'Bearer ${idToken ?? ''}', 
    };
  }

  Future<AIResponse> processInput({
    String? text,
    String? fileText,
    String? fileName,
  }) async {
    final decks = await _deckStorage.getDecks();
    final allCards = await _cardStorage.getAllCards();

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
        'isChat': false, 
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(_parseErrorMessage(response));
    }

    final dynamic decodedJson = jsonDecode(response.body);
    if (decodedJson is! Map) {
       throw Exception("Invalid response format from server.");
    }
    
    final Map<String, dynamic> decoded = Map<String, dynamic>.from(decodedJson as Map);
    
    final action = decoded['action']?.toString() ?? 'chat';
    final reply = decoded['reply']?.toString() ?? 'I processed your request.';

    Deck? newDeck;
    Deck? editedDeck;

    if (action == 'create_deck') {
      newDeck = await _handleCreateDeck(decoded, fileName);
    } else if (action == 'edit_deck') {
      editedDeck = await _handleEditDeck(decoded, decks);
    }

    return AIResponse(message: reply, generatedDeck: newDeck, editedDeck: editedDeck);
  }

  Future<AIResponse> processTutorChat({
    required String text,
    required Deck deck,
    required List<Flashcard> cards,
  }) async {
    
    final sb = StringBuffer();
    for (int i = 0; i < cards.length; i++) {
      final c = cards[i];
      sb.writeln("- Q: '${c.question}' -> A: '${c.answer}'");
    }
    
    final String deckContext = "The user is studying the deck '${deck.name}' (Subject: ${deck.subject}).\n"
        "Here are the flashcards currently in this deck:\n" + sb.toString();

    final headers = await _getSecureHeaders();

    final response = await _httpClient.post(
      Uri.parse(_backendUrl),
      headers: headers,
      body: jsonEncode({
        'prompt': "CRITICAL RULE: You are ONLY a study tutor. You are STRICTLY FORBIDDEN from creating, updating, editing, or deleting any flashcards. ALWAYS respond with the action 'chat' and act as a conversational tutor helping the user master the current deck.\n\nUser Message: $text",
        'userContext': deckContext,
        'isChat': true, 
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(_parseErrorMessage(response));
    }

    final dynamic decodedJson = jsonDecode(response.body);
    if (decodedJson is! Map) {
       throw Exception("Invalid response format from server.");
    }
    
    final Map<String, dynamic> decoded = Map<String, dynamic>.from(decodedJson as Map);

    final reply = decoded['reply']?.toString() ?? 'I processed your request.';

    return AIResponse(message: reply);
  }

  String _buildUserContext(List<Deck> decks, List<Flashcard> allCards) {
    if (decks.isEmpty) return 'The user currently has no saved decks.';

    final Map<String, List<Flashcard>> cardsByDeck = {};
    for (final card in allCards) {
      if (!cardsByDeck.containsKey(card.deckId)) {
        cardsByDeck[card.deckId] = <Flashcard>[];
      }
      cardsByDeck[card.deckId]!.add(card);
    }

    final buffer = StringBuffer('The user currently has the following study decks saved in their library:\n');
    for (final deck in decks) {
      final deckCards = cardsByDeck[deck.id] ?? <Flashcard>[];
      buffer.write('- Deck Name: \'${deck.name}\' (Subject: ${deck.subject}, ID: ${deck.id}). It contains ${deckCards.length} cards.\n');
      if (deckCards.isNotEmpty) {
        final first = deckCards.first;
        buffer.write('  Examples: Q: \'${first.question}\' -> A: \'${first.answer}\'\n');
      }
    }
    return buffer.toString();
  }

  Future<Deck?> _handleCreateDeck(Map<String, dynamic> data, String? fileName) async {
    final dynamic rawCards = data['cards'];
    if (rawCards is! Iterable || rawCards.isEmpty) return null;
    
    final newDeck = Deck(
      id: _uuid.v4(),
      name: data['deckName']?.toString() ?? (fileName != null ? 'Notes from $fileName' : 'AI Generated Deck'),
      subject: data['subject']?.toString() ?? 'Generated Study Material',
      cardCount: rawCards.length,
    );

    final List<Flashcard> newCards = <Flashcard>[];
    for (var cardData in rawCards) {
      if (cardData is Map) {
        newCards.add(Flashcard(
          id: _uuid.v4(),
          deckId: newDeck.id,
          question: cardData['q']?.toString() ?? '',
          answer: cardData['a']?.toString() ?? '',
        ));
      }
    }

    await _deckStorage.addDeck(newDeck);
    await _cardStorage.addCards(newCards);

    return newDeck;
  }

  Future<Deck?> _handleEditDeck(Map<String, dynamic> data, List<Deck> decks) async {
    final targetId = data['targetDeckId']?.toString();
    final dynamic rawCards = data['cards'];

    if (targetId == null || rawCards is! Iterable || rawCards.isEmpty) return null;
    
    final int index = decks.indexWhere((d) => d.id == targetId);
    if (index == -1) return null;

    final Deck editedDeck = decks[index];
    
    final List<Flashcard> newCards = <Flashcard>[];
    for (var cardData in rawCards) {
      if (cardData is Map) {
        newCards.add(Flashcard(
          id: _uuid.v4(),
          deckId: editedDeck.id,
          question: cardData['q']?.toString() ?? '',
          answer: cardData['a']?.toString() ?? '',
        ));
      }
    }

    editedDeck.cardCount += newCards.length;

    await _cardStorage.addCards(newCards);
    await _deckStorage.updateDeck(editedDeck);

    return editedDeck;
  }

  String _parseErrorMessage(http.Response response) {
    if (response.statusCode == 403) {
      try {
        final decodedJson = jsonDecode(response.body);
        if (decodedJson is Map) {
           final decoded = Map<String, dynamic>.from(decodedJson as Map);
           return decoded['error']?.toString() ?? 'Out of energy! Please watch an ad to recharge.';
        }
      } catch (_) {}
      return 'Out of energy! Please watch an ad to recharge.';
    }
    
    try {
      final decodedJson = jsonDecode(response.body);
      if (decodedJson is Map) {
        final decoded = Map<String, dynamic>.from(decodedJson as Map);
        final details = decoded['details']?.toString() ?? '';
        if (details.contains('503') || details.contains('high demand')) {
          return 'The AI service is currently experiencing high demand. Please try again in a few moments.';
        }
        final error = decoded['error']?.toString();
        if (error != null) return 'Server error ${response.statusCode}\nError: $error';
        if (details.isNotEmpty) return 'Server error ${response.statusCode}\nDetails: $details';
      }
    } catch (_) {}
    return 'Server error ${response.statusCode}\nBody: ${response.body}';
  }
}