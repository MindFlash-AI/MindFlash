import 'dart:convert';

class Deck {
  final String id;
  final String name;
  final String subject;
  int cardCount;

  Deck({
    required this.id,
    required this.name,
    required this.subject,
    this.cardCount = 0,
  });

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'subject': subject, 'cardCount': cardCount};
  }

  factory Deck.fromMap(Map<String, dynamic> map) {
    return Deck(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      subject: map['subject'] ?? '',
      cardCount: map['cardCount']?.toInt() ?? 0,
    );
  }

  String toJson() => json.encode(toMap());

  factory Deck.fromJson(String source) => Deck.fromMap(json.decode(source));
}
