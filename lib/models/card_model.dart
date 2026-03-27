import 'dart:convert';

class Flashcard {
  final String id;
  final String deckId;
  final String question;
  final String answer;
  bool isFlagged;
  bool isMastered;

  Flashcard({
    required this.id,
    required this.deckId,
    required this.question,
    required this.answer,
    this.isFlagged = false,
    this.isMastered = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'deckId': deckId,
      'question': question,
      'answer': answer,
      'isFlagged': isFlagged,
      'isMastered': isMastered,
    };
  }

  factory Flashcard.fromMap(Map<String, dynamic> map) {
    return Flashcard(
      id: map['id'] ?? '',
      deckId: map['deckId'] ?? '',
      question: map['question'] ?? '',
      answer: map['answer'] ?? '',
      isFlagged: map['isFlagged'] ?? false,
      isMastered: map['isMastered'] ?? false,
    );
  }

  String toJson() => json.encode(toMap());

  factory Flashcard.fromJson(String source) =>
      Flashcard.fromMap(json.decode(source));
}
