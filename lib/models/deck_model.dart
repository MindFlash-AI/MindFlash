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
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory Deck.fromMap(Map<String, dynamic> map) {
    DateTime parsedDate = DateTime.now();

    final rawDate = map['createdAt'];
    if (rawDate is Timestamp) {
      parsedDate = rawDate.toDate();
    } else if (rawDate is String) {
      try {
        parsedDate = DateTime.parse(rawDate);
      } catch (_) {}
    } else if (rawDate is int) {
      parsedDate = DateTime.fromMillisecondsSinceEpoch(rawDate);
    }

    return Deck(
      // 🛡️ WEB FIX: Safe String Parsing
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      subject: map['subject']?.toString() ?? '',

      // 🛡️ WEB FIX: Safe Int Parsing
      cardCount: (map['cardCount'] as num?)?.toInt() ?? 0,

      createdAt: parsedDate,
    );
  }
  
  String toJson() => json.encode({
    'id': id,
    'name': name,
    'subject': subject,
    'cardCount': cardCount,
    'createdAt': createdAt.toIso8601String(),
  });

  // 🛡️ WEB FIX: Safely map decoded JSON
  factory Deck.fromJson(String source) =>
      Deck.fromMap(Map<String, dynamic>.from(json.decode(source) as Map));

  Deck copyWith({
    String? id,
    String? name,
    String? subject,
    int? cardCount,
    DateTime? createdAt,
  }) {
    return Deck(
      id: id ?? this.id,
      name: name ?? this.name,
      subject: subject ?? this.subject,
      cardCount: cardCount ?? this.cardCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}