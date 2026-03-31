import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

class Flashcard {
  final String id;
  final String deckId;
  final String question;
  final String answer;
  
  bool isMastered;
  bool isFlagged;

  int repetitions;
  double easeFactor;
  int interval; 
  DateTime nextReviewDate;
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
      // Use Firestore Timestamp for accurate Cloud queries
      'nextReviewDate': Timestamp.fromDate(nextReviewDate), 
      'lastScore': lastScore, 
    };
  }

  factory Flashcard.fromMap(Map<String, dynamic> map) {
    DateTime parsedDate = DateTime.now();
    if (map['nextReviewDate'] != null) {
      if (map['nextReviewDate'] is Timestamp) {
        parsedDate = (map['nextReviewDate'] as Timestamp).toDate();
      } else if (map['nextReviewDate'] is String) {
        parsedDate = DateTime.parse(map['nextReviewDate']);
      }
    }

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
      nextReviewDate: parsedDate,
      lastScore: map['lastScore']?.toInt(),
    );
  }

  String toJson() => json.encode({
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
        'lastScore': lastScore,
      });

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