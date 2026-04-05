import 'dart:convert';

class QuizQuestion {
  final String question;
  final String correctAnswer;
  final List<String> options;

  QuizQuestion({
    required this.question,
    required this.correctAnswer,
    required this.options,
  });

  Map<String, dynamic> toMap() {
    return {
      'question': question,
      'correctAnswer': correctAnswer,
      'options': options,
    };
  }

  factory QuizQuestion.fromMap(Map<String, dynamic> map) {
    return QuizQuestion(
      question: map['question']?.toString() ?? '',
      correctAnswer: map['correctAnswer']?.toString() ?? '',
      
      // 🛡️ WEB FIX: Safely parse dynamic list to a strict List<String>
      options: map['options'] is List 
          ? (map['options'] as List).map((e) => e.toString()).toList() 
          : [],
    );
  }

  String toJson() => json.encode(toMap());

  // 🛡️ WEB FIX: Safely map decoded JSON
  factory QuizQuestion.fromJson(String source) => 
      QuizQuestion.fromMap(Map<String, dynamic>.from(json.decode(source) as Map));
}