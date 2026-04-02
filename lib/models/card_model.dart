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
      'nextReviewDate': Timestamp.fromDate(nextReviewDate),
      'lastScore': lastScore,
    };
  }

  factory Flashcard.fromMap(Map<String, dynamic> map) {
    DateTime parsedDate = DateTime.now();

    final rawDate = map['nextReviewDate'];
    if (rawDate is Timestamp) {
      parsedDate = rawDate.toDate();
    } else if (rawDate is String) {
      try {
        parsedDate = DateTime.parse(rawDate);
      } catch (_) {}
    } else if (rawDate is int) {
      parsedDate = DateTime.fromMillisecondsSinceEpoch(rawDate);
    }

    return Flashcard(
      // 🛡️ WEB FIX: Safe String Parsing
      id: map['id']?.toString() ?? '',
      deckId: map['deckId']?.toString() ?? '',
      question: map['question']?.toString() ?? '',
      answer: map['answer']?.toString() ?? '',
      
      // 🛡️ WEB FIX: Safe Boolean Parsing
      isMastered: map['isMastered'] == true,
      isFlagged: map['isFlagged'] == true,

      // 🛡️ WEB FIX: Safe Number Parsing
      repetitions: (map['repetitions'] as num?)?.toInt() ?? 0,
      easeFactor: (map['easeFactor'] as num?)?.toDouble() ?? 2.5,
      interval: (map['interval'] as num?)?.toInt() ?? 0,
      lastScore: (map['lastScore'] as num?)?.toInt(),
      
      nextReviewDate: parsedDate,
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

  // 🛡️ WEB FIX: Safely map decoded JSON to a strict Map
  factory Flashcard.fromJson(String source) =>
      Flashcard.fromMap(Map<String, dynamic>.from(json.decode(source) as Map));

  Flashcard copyWith({
    String? id,
    String? deckId,
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
      id: id ?? this.id,
      deckId: deckId ?? this.deckId,
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