import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/note_model.dart';

class NoteStorageService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  CollectionReference get _notesCollection {
    final userId = currentUserId;
    if (userId == null) throw Exception('User not logged in');
    return _firestore.collection('users').doc(userId).collection('notes');
  }

  Future<List<Note>> getNotes() async {
    if (currentUserId == null) return [];
    
    try {
      final snapshot = await _notesCollection.orderBy('updatedAt', descending: true).get();
      return snapshot.docs
          .map((doc) => Note.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> saveNote(Note note) async {
    if (currentUserId == null) return;
    await _notesCollection.doc(note.id).set(note.toMap());
  }

  Future<void> deleteNote(String noteId) async {
    if (currentUserId == null) return;
    await _notesCollection.doc(noteId).delete();
  }
}