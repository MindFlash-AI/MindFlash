import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

class Deck {
  final String id;
  String name;
  String subject;
  int cardCount;
  final DateTime createdAt;

  Deck({
    required this.id,
    required this.name,
    required this.subject,
    this.cardCount = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'subject': subject,
      'cardCount': cardCount,
      // Use Firestore Timestamp for the database
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory Deck.fromMap(Map<String, dynamic> map) {
    // Safely parse dates coming from either Firestore (Timestamp) or local fallback (String)
    DateTime parsedDate = DateTime.now();
    if (map['createdAt'] != null) {
      if (map['createdAt'] is Timestamp) {
        parsedDate = (map['createdAt'] as Timestamp).toDate();
      } else if (map['createdAt'] is String) {
        parsedDate = DateTime.parse(map['createdAt']);
      }
    }

    return Deck(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      subject: map['subject'] ?? '',
      cardCount: map['cardCount']?.toInt() ?? 0,
      createdAt: parsedDate,
    );
  }

  // Fallback JSON methods if you ever need to serialize outside of Firestore
  String toJson() => json.encode({
        'id': id,
        'name': name,
        'subject': subject,
        'cardCount': cardCount,
        'createdAt': createdAt.toIso8601String(),
      });

  factory Deck.fromJson(String source) => Deck.fromMap(json.decode(source));
}