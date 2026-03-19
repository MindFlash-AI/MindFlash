import 'dart:convert';

class Flashcard {
  final String id;
  final String deckId;
  final String question;
  final String answer;

  Flashcard({
    required this.id,
    required this.deckId,
    required this.question,
    required this.answer,
  });

  Map<String, dynamic> toMap() {
    return {'id': id, 'deckId': deckId, 'question': question, 'answer': answer};
  }

  factory Flashcard.fromMap(Map<String, dynamic> map) {
    return Flashcard(
      id: map['id'] ?? '',
      deckId: map['deckId'] ?? '',
      question: map['question'] ?? '',
      answer: map['answer'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory Flashcard.fromJson(String source) =>
      Flashcard.fromMap(json.decode(source));
}
