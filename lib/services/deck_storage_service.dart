import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/deck_model.dart';

class DeckStorageService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Ensures we only fetch/save data for the currently logged-in user
  String? get _uid => _auth.currentUser?.uid;

  CollectionReference get _decksRef {
    if (_uid == null) throw Exception("User not authenticated.");
    return _firestore.collection('users').doc(_uid).collection('decks');
  }

  Future<List<Deck>> getDecks() async {
    try {
      if (_uid == null) return [];
      final snapshot = await _decksRef.orderBy('createdAt', descending: true).get();
      return snapshot.docs
          .map((doc) => Deck.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print("Error fetching decks from Firestore: $e");
      return [];
    }
  }

  Future<void> addDeck(Deck deck) async {
    try {
      if (_uid == null) return;
      await _decksRef.doc(deck.id).set(deck.toMap());
    } catch (e) {
      print("Error adding deck to Firestore: $e");
    }
  }

  Future<void> updateDeck(Deck updatedDeck) async {
    try {
      if (_uid == null) return;
      await _decksRef.doc(updatedDeck.id).update(updatedDeck.toMap());
    } catch (e) {
      print("Error updating deck in Firestore: $e");
    }
  }

  Future<void> deleteDeck(String deckId) async {
    try {
      if (_uid == null) return;
      await _decksRef.doc(deckId).delete();
    } catch (e) {
      print("Error deleting deck from Firestore: $e");
    }
  }
}