import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

class Deck {
  final String id;
  String name;
  String subject;
  int cardCount;
  List<String> cardOrder;
  final DateTime createdAt;

  Deck({
    required this.id,
    required this.name,
    required this.subject,
    this.cardCount = 0,
    this.cardOrder = const [],
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    final safeName = name.length > 499 ? name.substring(0, 499) : name;
    return {
      'id': id,
      'name': safeName,
      'subject': subject,
      'cardCount': cardCount,
      'cardOrder': cardOrder,
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
      cardOrder: map['cardOrder'] != null ? List<String>.from(map['cardOrder']) : [],

      createdAt: parsedDate,
    );
  }
  
  String toJson() => json.encode({
    'id': id,
    'name': name,
    'subject': subject,
    'cardCount': cardCount,
    'cardOrder': cardOrder,
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
    List<String>? cardOrder,
    DateTime? createdAt,
  }) {
    return Deck(
      id: id ?? this.id,
      name: name ?? this.name,
      subject: subject ?? this.subject,
      cardCount: cardCount ?? this.cardCount,
      cardOrder: cardOrder ?? this.cardOrder,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}