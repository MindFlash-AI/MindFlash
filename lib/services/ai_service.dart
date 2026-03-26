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

  AIResponse({required this.message, this.generatedDeck, this.editedDeck});
}

class AIService {
  final DeckStorageService _deckStorage = DeckStorageService();
  final CardStorageService _cardStorage = CardStorageService();

  final String backendUrl = dotenv.env['BACKEND_URL']!;

  Future<AIResponse> processInput({
    String? text,
    String? fileText,
    String? fileName,
  }) async {
    final decks = await _deckStorage.getDecks();
    final allCards = await _cardStorage.getAllCards();

    String userDataContext = "The user currently has no saved decks.";
    if (decks.isNotEmpty) {
      userDataContext =
          "The user currently has the following study decks saved in their library:\n";
      for (var deck in decks) {
        final deckCards = allCards.where((c) => c.deckId == deck.id).toList();
        userDataContext +=
            "- Deck Name: '${deck.name}' (Subject: ${deck.subject}, ID: ${deck.id}). It contains ${deckCards.length} cards.\n";

        if (deckCards.isNotEmpty) {
          userDataContext +=
              "  Examples: Q: '${deckCards.first.question}' -> A: '${deckCards.first.answer}'\n";
        }
      }
    }

    try {
      final response = await http.post(
        Uri.parse(backendUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'prompt': text,
          'fileText': fileText,
          'fileName': fileName,
          'userContext': userDataContext,
        }),
      );

      if (response.statusCode != 200) {
        String errorMessage = "Server error: ${response.statusCode}";
        try {
          final errorData = jsonDecode(response.body);
          if (errorData['details'] != null) {
            final details = errorData['details'].toString();

            if (details.contains("503") || details.contains("high demand")) {
              errorMessage =
                  "The AI service is currently experiencing high demand. Please try again in a few moments.";
            } else {
              errorMessage += "\nDetails: $details";
            }
          } else if (errorData['error'] != null) {
            errorMessage += "\nError: ${errorData['error']}";
          }
        } catch (_) {
          errorMessage += "\nBody: ${response.body}";
        }
        throw Exception(errorMessage);
      }

      final Map<String, dynamic> data = jsonDecode(response.body);

      final String action = data['action'] ?? 'chat';
      final String reply = data['reply'] ?? "I processed your request.";

      Deck? newDeck;
      Deck? editedDeck;

      if (action == 'create_deck' && data['cards'] != null) {
        final List<dynamic> cardsData = data['cards'];

        if (cardsData.isNotEmpty) {
          newDeck = Deck(
            id: const Uuid().v4(),
            name:
                data['deckName'] ??
                (fileName != null
                    ? "Notes from $fileName"
                    : "AI Generated Deck"),
            subject: data['subject'] ?? "Generated Study Material",
            cardCount: cardsData.length,
          );
          await _deckStorage.addDeck(newDeck);

          for (var cardData in cardsData) {
            final newCard = Flashcard(
              id: const Uuid().v4(),
              deckId: newDeck.id,
              question: cardData['q'].toString(),
              answer: cardData['a'].toString(),
            );
            await _cardStorage.addCard(newCard);
          }
        }
      } else if (action == 'edit_deck' &&
          data['targetDeckId'] != null &&
          data['cards'] != null) {
        final targetId = data['targetDeckId'];
        final decks = await _deckStorage.getDecks();
        final index = decks.indexWhere((d) => d.id == targetId);

        if (index != -1) {
          editedDeck = decks[index];
          final List<dynamic> cardsData = data['cards'];

          if (cardsData.isNotEmpty) {
            for (var cardData in cardsData) {
              final newCard = Flashcard(
                id: const Uuid().v4(),
                deckId: editedDeck.id,
                question: cardData['q'].toString(),
                answer: cardData['a'].toString(),
              );
              await _cardStorage.addCard(newCard);
            }

            editedDeck.cardCount += cardsData.length;
            await _deckStorage.updateDeck(editedDeck);
          }
        }
      }

      return AIResponse(
        message: reply,
        generatedDeck: newDeck,
        editedDeck: editedDeck,
      );
    } catch (e) {
      if (e.toString().contains("Exception: The AI service")) {
        rethrow;
      }
      throw Exception("Failed to connect to backend: $e");
    }
  }
}
