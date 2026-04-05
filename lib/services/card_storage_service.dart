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
          .map((doc) {
            final data = doc.data();
            if (data is Map) {
              return Flashcard.fromMap(Map<String, dynamic>.from(data));
            }
            return null;
          })
          .whereType<Flashcard>()
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

  // 🛡️ SECURITY FIX 1: Array Chunking for Batches
  // Firestore strictly limits batches to 500 writes. If the AI generates 501+ cards,
  // the app would crash. We now slice them into safe chunks of 450.
  Future<void> addCards(List<Flashcard> cards) async {
    try {
      if (_uid == null) return;
      
      const int chunkSize = 450;
      for (var i = 0; i < cards.length; i += chunkSize) {
        final batch = _firestore.batch();
        final chunk = cards.skip(i).take(chunkSize);
        
        for (var card in chunk) {
          batch.set(_cardsRef.doc(card.id), card.toMap());
        }
        await batch.commit();
      }
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

  Future<void> deleteCards(List<String> cardIds) async {
    try {
      if (_uid == null || cardIds.isEmpty) return;

      const int chunkSize = 450;
      for (var i = 0; i < cardIds.length; i += chunkSize) {
        final batch = _firestore.batch();
        final chunk = cardIds.skip(i).take(chunkSize);
        
        for (var id in chunk) {
          batch.delete(_cardsRef.doc(id));
        }
        await batch.commit();
      }
    } catch (e) {
      print("Error deleting multiple cards: $e");
    }
  }

  // 🛡️ SECURITY FIX 1 (Cont): Chunking deletes to prevent orphans
  Future<void> deleteCardsByDeck(String deckId) async {
    try {
      if (_uid == null) return;

      final query = await _cardsRef.where('deckId', isEqualTo: deckId).get();
      final docs = query.docs;

      const int chunkSize = 450;
      for (var i = 0; i < docs.length; i += chunkSize) {
        final batch = _firestore.batch();
        final chunk = docs.skip(i).take(chunkSize);
        
        for (var doc in chunk) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      }
    } catch (e) {
      print("Error deleting cards by deck: $e");
    }
  }

  // 🛡️ SECURITY FIX 1 (Cont): Chunking updates
  Future<void> resetStatsForDeck(String deckId) async {
    try {
      if (_uid == null) return;

      final query = await _cardsRef.where('deckId', isEqualTo: deckId).get();
      final docs = query.docs;

      const int chunkSize = 450;
      for (var i = 0; i < docs.length; i += chunkSize) {
        final batch = _firestore.batch();
        final chunk = docs.skip(i).take(chunkSize);
        
        for (var doc in chunk) {
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
      }
    } catch (e) {
      print("Error resetting stats: $e");
    }
  }

  Future<List<Flashcard>> getCardsForDeck(String deckId) async {
    try {
      if (_uid == null) return [];

      final snapshot = await _cardsRef.where('deckId', isEqualTo: deckId).get();

      return snapshot.docs
          .map((doc) {
            final data = doc.data();
            if (data is Map) {
              return Flashcard.fromMap(Map<String, dynamic>.from(data));
            }
            return null;
          })
          .whereType<Flashcard>()
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
          .where('nextReviewDate', isLessThanOrEqualTo: now)
          .get();

      return snapshot.docs
          .map((doc) {
            final data = doc.data();
            if (data is Map) {
              return Flashcard.fromMap(Map<String, dynamic>.from(data));
            }
            return null;
          })
          .whereType<Flashcard>()
          .toList();
    } catch (e) {
      print("Error fetching due cards: $e");
      return [];
    }
  }
}