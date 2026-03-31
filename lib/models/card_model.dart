import 'dart:convert';

class Flashcard {
  final String id;
  final String deckId;
  final String question;
  final String answer;
  
  bool isMastered;
  bool isFlagged;

  // SRS Fields
  int repetitions;
  double easeFactor;
  int interval; // In days
  DateTime nextReviewDate;
  
  // NEW: Tracks the exact button the user pressed last time (0, 3, 4, 5)
  int? lastScore; 

  Flashcard({
    required this.id,
    required this.deckId,
    required this.question,
    required this.answer,
    this.isMastered = false,
    this.isFlagged = false,
    this.repetitions = 0,
    this.easeFactor = 2.5,
    this.interval = 0,
    DateTime? nextReviewDate,
    this.lastScore,
  }) : nextReviewDate = nextReviewDate ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'deckId': deckId,
      'question': question,
      'answer': answer,
      'isMastered': isMastered,
      'isFlagged': isFlagged,
      'repetitions': repetitions,
      'easeFactor': easeFactor,
      'interval': interval,
      'nextReviewDate': nextReviewDate.toIso8601String(), 
      'lastScore': lastScore, // Save the new field
    };
  }

  factory Flashcard.fromMap(Map<String, dynamic> map) {
    return Flashcard(
      id: map['id'] ?? '',
      deckId: map['deckId'] ?? '',
      question: map['question'] ?? '',
      answer: map['answer'] ?? '',
      isMastered: map['isMastered'] ?? false,
      isFlagged: map['isFlagged'] ?? false,
      repetitions: map['repetitions']?.toInt() ?? 0,
      easeFactor: (map['easeFactor'] ?? 2.5).toDouble(),
      interval: map['interval']?.toInt() ?? 0,
      nextReviewDate: map['nextReviewDate'] != null 
          ? DateTime.parse(map['nextReviewDate']) 
          : DateTime.now(),
      lastScore: map['lastScore']?.toInt(), // Load the new field
    );
  }

  String toJson() => json.encode(toMap());

  factory Flashcard.fromJson(String source) => Flashcard.fromMap(json.decode(source));

  Flashcard copyWith({
    String? question,
    String? answer,
    bool? isMastered,
    bool? isFlagged,
    int? repetitions,
    double? easeFactor,
    int? interval,
    DateTime? nextReviewDate,
    int? lastScore,
  }) {
    return Flashcard(
      id: id,
      deckId: deckId,
      question: question ?? this.question,
      answer: answer ?? this.answer,
      isMastered: isMastered ?? this.isMastered,
      isFlagged: isFlagged ?? this.isFlagged,
      repetitions: repetitions ?? this.repetitions,
      easeFactor: easeFactor ?? this.easeFactor,
      interval: interval ?? this.interval,
      nextReviewDate: nextReviewDate ?? this.nextReviewDate,
      lastScore: lastScore ?? this.lastScore,
    );
  }
}