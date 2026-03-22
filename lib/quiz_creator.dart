import 'dart:math';
import 'quiz_question.dart';
import 'card_model.dart';

class _AnswerProfile {
  final String text;
  final bool hasNumber;
  final int wordCount;
  final int length;

  _AnswerProfile(this.text)
    : hasNumber = RegExp(r'\d').hasMatch(text),
      wordCount = text.trim().split(RegExp(r'\s+')).length,
      length = text.length;
}

class LocalQuizEngine {
  static List<QuizQuestion> generateMCQ(List<Flashcard> deck) {
    if (deck.length < 4) {
      throw Exception('Deck must contain at least 4 cards to generate a quiz.');
    }

    final random = Random();
    List<QuizQuestion> quiz = [];

    final List<_AnswerProfile> allProfiles = deck
        .map((c) => _AnswerProfile(c.answer))
        .toList();

    for (int i = 0; i < deck.length; i++) {
      final currentCard = deck[i];
      final correctProfile = allProfiles[i];

      final Set<String> uniqueDistractors = {correctProfile.text};

      List<Map<String, dynamic>> scoredDistractors = [];

      for (int j = 0; j < allProfiles.length; j++) {
        if (i == j) continue;

        final candidateProfile = allProfiles[j];

        if (!uniqueDistractors.contains(candidateProfile.text)) {
          int score = _calculateFastScore(correctProfile, candidateProfile);
          scoredDistractors.add({
            'text': candidateProfile.text,
            'score': score,
          });
          uniqueDistractors.add(candidateProfile.text);
        }
      }

      if (scoredDistractors.length < 3) {
        throw Exception(
          'Not enough unique answers in the deck to create a valid multiple-choice quiz.',
        );
      }

      scoredDistractors.sort((a, b) => b['score'].compareTo(a['score']));

      final int poolSize = min(5, scoredDistractors.length);
      final topTrickiest = scoredDistractors
          .take(poolSize)
          .map((e) => e['text'] as String)
          .toList();
      topTrickiest.shuffle(random);

      List<String> finalOptions = topTrickiest.take(3).toList();
      finalOptions.add(correctProfile.text);
      finalOptions.shuffle(random);

      quiz.add(
        QuizQuestion(
          question: currentCard.question,
          correctAnswer: correctProfile.text,
          options: finalOptions,
        ),
      );
    }

    quiz.shuffle(random);
    return quiz;
  }

  static int _calculateFastScore(
    _AnswerProfile correct,
    _AnswerProfile distractor,
  ) {
    int score = 0;

    if (correct.hasNumber && distractor.hasNumber) {
      score += 10;
    } else if (!correct.hasNumber && !distractor.hasNumber) {
      score += 2;
    } else {
      score -= 5;
    }

    int diffWords = (correct.wordCount - distractor.wordCount).abs();
    if (diffWords == 0) {
      score += 5;
    } else if (diffWords <= 2) {
      score += 3;
    } else if (diffWords > 5) {
      score -= 5;
    }

    int lengthDiff = (correct.length - distractor.length).abs();
    if (lengthDiff < 5) {
      score += 3;
    } else if (lengthDiff < 15) {
      score += 1;
    }

    return score;
  }
}
