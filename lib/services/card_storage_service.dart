import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/card_model.dart';

class CardStorageService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  CollectionReference get _cardsRef {
    if (_uid == null) throw Exception("User not authenticated.");
    return _firestore.collection('users').doc(_uid).collection('cards');
  }

  Future<List<Flashcard>> getAllCards() async {
    try {
      if (_uid == null) return [];
      final snapshot = await _cardsRef.get();
      return snapshot.docs
          .map((doc) => Flashcard.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print("Error fetching all cards: $e");
      return [];
    }
  }

  Future<void> addCard(Flashcard card) async {
    try {
      if (_uid == null) return;
      await _cardsRef.doc(card.id).set(card.toMap());
    } catch (e) {
      print("Error adding card: $e");
    }
  }

  // Uses Firestore Batch to upload AI generated quizzes instantly
  Future<void> addCards(List<Flashcard> cards) async {
    try {
      if (_uid == null) return;
      final batch = _firestore.batch();
      for (var card in cards) {
        batch.set(_cardsRef.doc(card.id), card.toMap());
      }
      await batch.commit();
    } catch (e) {
      print("Error adding multiple cards: $e");
    }
  }

  Future<void> updateCard(Flashcard updatedCard) async {
    try {
      if (_uid == null) return;
      await _cardsRef.doc(updatedCard.id).update(updatedCard.toMap());
    } catch (e) {
      print("Error updating card: $e");
    }
  }

  Future<void> deleteCard(String cardId) async {
    try {
      if (_uid == null) return;
      await _cardsRef.doc(cardId).delete();
    } catch (e) {
      print("Error deleting card: $e");
    }
  }

  // Safely deletes all cards inside a deck when the deck is deleted
  Future<void> deleteCardsByDeck(String deckId) async {
    try {
      if (_uid == null) return;
      final query = await _cardsRef.where('deckId', isEqualTo: deckId).get();
      final batch = _firestore.batch();
      for (var doc in query.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      print("Error deleting cards by deck: $e");
    }
  }

  Future<void> resetStatsForDeck(String deckId) async {
    try {
      if (_uid == null) return;
      final query = await _cardsRef.where('deckId', isEqualTo: deckId).get();
      final batch = _firestore.batch();
      for (var doc in query.docs) {
        batch.update(doc.reference, {
          'isMastered': false,
          'isFlagged': false,
          'repetitions': 0,
          'easeFactor': 2.5,
          'interval': 0,
          'nextReviewDate': Timestamp.fromDate(DateTime.now()),
          'lastScore': null,
        });
      }
      await batch.commit();
    } catch (e) {
      print("Error resetting stats: $e");
    }
  }

  Future<List<Flashcard>> getCardsForDeck(String deckId) async {
    try {
      if (_uid == null) return [];
      final snapshot = await _cardsRef.where('deckId', isEqualTo: deckId).get();
      return snapshot.docs
          .map((doc) => Flashcard.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print("Error fetching cards for deck: $e");
      return [];
    }
  }

  Future<List<Flashcard>> getDueCardsForDeck(String deckId) async {
    try {
      if (_uid == null) return [];
      final now = Timestamp.fromDate(DateTime.now());
      final snapshot = await _cardsRef
          .where('deckId', isEqualTo: deckId)
          // FIRESTORE MAGIC: Offloads the date math to Google's servers
          .where('nextReviewDate', isLessThanOrEqualTo: now)
          .get();
          
      return snapshot.docs
          .map((doc) => Flashcard.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print("Error fetching due cards: $e");
      return [];
    }
  }
}