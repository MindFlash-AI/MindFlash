import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

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
    String? targetDeckId, // 🛡️ NEW: Pass the target deck ID if we are updating!
  }) async {
    // 💰 COST & BANDWIDTH OPTIMIZATION: Truncate massive payloads client-side
    // Prevents uploading massive 10MB+ strings just for the server to truncate them, saving network egress costs.
    if (text != null && text.length > 2000) text = '${text.substring(0, 2000)}...[TRUNCATED]';
    if (fileText != null && !fileText.startsWith('data:image/') && fileText.length > 35000) {
      fileText = '${fileText.substring(0, 35000)}...[TRUNCATED]';
    }

    final decks = await _deckStorage.getDecks();
    
    // 🛡️ SECURITY FIX: Enforce Maximum 20 Decks per User
    if (targetDeckId == null && decks.length >= 20) {
      throw Exception("You have reached the maximum limit of 20 decks. Please delete some decks to create new ones! 🛑");
    }

    // 🛡️ FIX: If we are updating a deck, we MUST fetch its existing cards
    // so we can tell the AI what is already in it, preventing duplicates!
    List<Flashcard> existingCards = [];
    if (targetDeckId != null) {
      existingCards = await _cardStorage.getCardsForDeck(targetDeckId);
      
      // 🛡️ SECURITY FIX: Enforce Maximum 100 Cards per Deck
      if (existingCards.length >= 100) {
         throw Exception("This deck is completely full (100 cards max)! Please update a different deck. 🛑");
      }
    }

    final String userDataContext = _buildUserContext(decks, existingCards, targetDeckId);
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
    required List<Map<String, dynamic>> chatHistory, 
  }) async {
    
    // 💰 COST OPTIMIZATION: Reduce sample size from 25 to 10.
    // This saves ~500-1000 tokens per chat message while keeping the AI perfectly contextualized.
    final List<Flashcard> sampledCards = cards.length > 10 
        ? (cards.toList()..shuffle()).sublist(0, 10) 
        : cards;

    final sb = StringBuffer();
    for (int i = 0; i < sampledCards.length; i++) {
      final c = sampledCards[i];
      sb.writeln("- Q: '${c.question}' -> A: '${c.answer}'");
    }
    
    String deckContext = "The user is studying the deck '${deck.name}' (Subject: ${deck.subject}).\n"
        "Here is a sample of the flashcards in this deck to give you context:\n" + sb.toString();

    if (chatHistory.isNotEmpty) {
      deckContext += "\n\n--- RECENT CHAT HISTORY ---\n";
      for (var msg in chatHistory) {
        final isUser = msg['isUser'] == true;
        String msgText = msg['text']?.toString() ?? '';
        
        if (msgText.length > 500) {
          msgText = msgText.substring(0, 500) + '...[TRUNCATED]';
        }
        
        deckContext += isUser ? "Student: $msgText\n" : "Tutor (You): $msgText\n";
      }
    }

    final headers = await _getSecureHeaders();

    final response = await _httpClient.post(
      Uri.parse(_backendUrl),
      headers: headers,
      body: jsonEncode({
        'prompt': text, // 🛡️ SECURITY FIX: System instructions must be enforced securely on the backend!
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

  // 🛡️ REBUILT CONTEXT BUILDER
  String _buildUserContext(List<Deck> decks, List<Flashcard> existingCards, String? targetDeckId) {
    if (decks.isEmpty) return 'The user currently has no saved decks.';

    final buffer = StringBuffer();
    
    if (targetDeckId != null && existingCards.isNotEmpty) {
      // 💰 COST OPTIMIZATION: If explicitly updating a deck, ONLY send that deck's context.
      buffer.write('CRITICAL: The user is asking to UPDATE this specific deck. Here are the flashcards ALREADY inside it. DO NOT generate duplicates of these:\n');
      final sample = existingCards.take(40).toList();
      for (var c in sample) {
        buffer.write('    -> Q: ${c.question} | A: ${c.answer}\n');
      }
    } else {
      // 💰 COST OPTIMIZATION: Limit general context to 10 decks instead of 30.
      final recentDecks = decks.take(10).toList();
      buffer.write('The user currently has the following study decks saved in their library:\n');
      for (final deck in recentDecks) {
        final safeName = deck.name.length > 80 ? deck.name.substring(0, 80) : deck.name;
        buffer.write('- Deck Name: \'$safeName\' (Subject: ${deck.subject}, ID: ${deck.id}).\n');
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
      if (newCards.length >= 100) break; // 🛡️ ENFORCE: Max 100 cards limit
      if (cardData is Map) {
        newCards.add(Flashcard(
          id: _uuid.v4(),
          deckId: newDeck.id,
          question: cardData['q']?.toString() ?? '',
          answer: cardData['a']?.toString() ?? '',
        ));
      }
    }

    newDeck.cardCount = newCards.length; // Ensure accurate count

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
    
    // 🛡️ ENFORCE: Max 100 cards limit
    final int availableSlots = 100 - editedDeck.cardCount;
    if (availableSlots <= 0) return editedDeck;

    final List<Flashcard> newCards = <Flashcard>[];
    for (var cardData in rawCards) {
      if (newCards.length >= availableSlots) break; // Drop any extra generated cards
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
           return decoded['error']?.toString() ?? 'It looks like you are out of energy! ⚡ Please watch a quick ad to recharge.';
        }
      } catch (_) {}
      return 'It looks like you are out of energy! ⚡ Please watch a quick ad to recharge.';
    }
    
    try {
      final decodedJson = jsonDecode(response.body);
      if (decodedJson is Map) {
        final decoded = Map<String, dynamic>.from(decodedJson as Map);
        final details = decoded['details']?.toString() ?? '';
        if (details.contains('503') || details.contains('high demand')) {
          return 'The AI is a little overwhelmed with students right now! 🎓 Please take a deep breath and try again in a few moments.';
        }
        final error = decoded['error']?.toString();
        if (error != null) return 'Oops, our servers had a tiny hiccup! 🛠️ Please try that again.\nError: $error';
        if (details.isNotEmpty) return 'Oops, our servers had a tiny hiccup! 🛠️ Please try that again.\nDetails: $details';
      }
    } catch (_) {}
    debugPrint('Server error ${response.statusCode}\nBody: ${response.body}');
    return 'Something unexpected happened behind the scenes! 🙈 Please try again later.';
  }
}