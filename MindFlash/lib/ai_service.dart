import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'deck_model.dart';
import 'card_model.dart';
import 'deck_storage_service.dart';
import 'card_storage_service.dart';

class AIResponse {
  final String message;
  final Deck? generatedDeck;
  final Deck? editedDeck; // Added support for edited decks

  AIResponse({required this.message, this.generatedDeck, this.editedDeck});
}

class AIService {
  final DeckStorageService _deckStorage = DeckStorageService();
  final CardStorageService _cardStorage = CardStorageService();
  late ChatSession _chat;
  bool isInitialized = false;

  Future<void> initChat() async {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty || apiKey == 'YOUR_API_KEY_HERE') {
      throw Exception("Please add your valid GEMINI_API_KEY in the .env file");
    }

    final decks = await _deckStorage.getDecks();
    final allCards = await _cardStorage.getAllCards();

    String userDataContext = "The user currently has no saved decks.";
    if (decks.isNotEmpty) {
      userDataContext = "The user currently has the following study decks saved in their library:\n";
      for (var deck in decks) {
        final deckCards = allCards.where((c) => c.deckId == deck.id).toList();
        // Crucial: We must provide the internal ID so Gemini can target it for edits
        userDataContext += "- Deck Name: '${deck.name}' (Subject: ${deck.subject}, ID: ${deck.id}). It contains ${deckCards.length} cards.\n";
        
        if (deckCards.isNotEmpty) {
          userDataContext += "  Examples: Q: '${deckCards.first.question}' -> A: '${deckCards.first.answer}'\n";
        }
      }
    }

    final model = GenerativeModel(
      model: 'gemini-2.5-flash', 
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
      ),
      systemInstruction: Content.system('''
You are MindFlash AI, a friendly and expert study assistant.

$userDataContext

Read the user's prompt carefully. 
- If they ask about their existing decks or progress, answer conversationally based on the context provided above.
- If they are just chatting, ask a question, or need an explanation, respond conversationally.
- If they ask you to ADD cards to an existing deck, generate the cards and select the action "edit_deck" using the correct targetDeckId.
- If they explicitly ask you to generate, create, or make a NEW flashcard deck, OR if they upload a document (and don't specify an existing deck), you MUST generate a new deck using the "create_deck" action.

ALWAYS return your response exactly in this JSON format:
{
  "action": "chat" | "create_deck" | "edit_deck",
  "reply": "Your conversational response here. Be encouraging.",
  "deckName": "Short descriptive name (ONLY if action is create_deck)",
  "subject": "General subject category (ONLY if action is create_deck)",
  "targetDeckId": "The exact ID of the existing deck (ONLY if action is edit_deck)",
  "cards": [
    {"q": "Question", "a": "Answer"}
  ] // (ONLY if action is create_deck OR edit_deck)
}
'''),
    );
    
    _chat = model.startChat();
    isInitialized = true;
  }

  Future<AIResponse> processInput({String? text, String? fileText, String? fileName}) async {
    if (!isInitialized) {
      await initChat();
    }

    String prompt = text ?? "";
    
    if (fileText != null && fileText.isNotEmpty) {
      prompt = "I have uploaded a document named '$fileName'. Here is the content:\n\n---\n$fileText\n---\n\nPlease extract the key concepts and generate a flashcard deck from this document, or add them to the deck I requested.";
    }

    try {
      final response = await _chat.sendMessage(Content.text(prompt));
      String responseText = response.text ?? '{}';
      
      responseText = responseText.replaceAll('```json', '').replaceAll('```', '').trim();

      final Map<String, dynamic> data = json.decode(responseText);
      
      final String action = data['action'] ?? 'chat';
      final String reply = data['reply'] ?? "I processed your request.";

      Deck? newDeck;
      Deck? editedDeck;

      // 1. Handle New Deck Creation
      if (action == 'create_deck' && data['cards'] != null) {
        final List<dynamic> cardsData = data['cards'];
        
        if (cardsData.isNotEmpty) {
          newDeck = Deck(
            id: const Uuid().v4(),
            name: data['deckName'] ?? (fileName != null ? "Notes from $fileName" : "AI Generated Deck"),
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
      } 
      // 2. Handle Existing Deck Editing
      else if (action == 'edit_deck' && data['targetDeckId'] != null && data['cards'] != null) {
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
            
            // Update the deck count and save
            editedDeck.cardCount += cardsData.length;
            await _deckStorage.updateDeck(editedDeck);
          }
        }
      }

      return AIResponse(message: reply, generatedDeck: newDeck, editedDeck: editedDeck);
      
    } catch (e) {
      throw Exception("Failed to process request: $e");
    }
  }
}