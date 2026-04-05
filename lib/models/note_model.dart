import 'package:cloud_firestore/cloud_firestore.dart';

class Note {
  final String id;
  final String title;
  final String content;
  final String drawingData;
  final DateTime updatedAt;
  final bool isTrashed;

  Note({
    required this.id,
    required this.title,
    required this.content,
    this.drawingData = '',
    required this.updatedAt,
    this.isTrashed = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'drawingData': drawingData,
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isTrashed': isTrashed,
    };
  }

  factory Note.fromMap(Map<String, dynamic> map, String documentId) {
    return Note(
      id: documentId,
      title: map['title'] ?? 'Untitled Note',
      content: map['content'] ?? '',
      drawingData: map['drawingData'] ?? '',
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isTrashed: map['isTrashed'] == true,
    );
  }
}