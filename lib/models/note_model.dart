import 'package:cloud_firestore/cloud_firestore.dart';

class Note {
  final String id;
  final String title;
  final String content;
  final DateTime updatedAt;

  Note({
    required this.id,
    required this.title,
    required this.content,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory Note.fromMap(Map<String, dynamic> map, String documentId) {
    return Note(
      id: documentId,
      title: map['title'] ?? 'Untitled Note',
      content: map['content'] ?? '',
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}