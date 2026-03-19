import 'dart:math';
import 'quiz_question.dart';
import 'card_model.dart';

// Assuming you have a basic Flashcard model like this:
// class Flashcard { final String front; final String back; }

class LocalQuizEngine {
  /// Transforms a list of Flashcards into a list of "Smart" Multiple Choice Questions
  static List<QuizQuestion> generateMCQ(List<Flashcard> deck) {
    if (deck.length < 4) {
      throw Exception('Deck must contain at least 4 cards to generate a quiz.');
    }

    List<QuizQuestion> quiz = [];
    final random = Random();

    for (int i = 0; i < deck.length; i++) {
      Flashcard currentCard = deck[i];
      String correctAnswer =
          currentCard.answer; // Assuming your model uses 'answer', not 'back'

      // 1. Get all possible wrong answers
      List<String> allWrongAnswers = deck
          .where((card) => card.id != currentCard.id)
          .map((card) => card.answer)
          .toList();

      // 2. Score them using our Heuristic Algorithm
      List<Map<String, dynamic>> scoredAnswers = allWrongAnswers.map((
        wrongAnswer,
      ) {
        int score = _calculateDistractorScore(correctAnswer, wrongAnswer);
        return {'answer': wrongAnswer, 'score': score};
      }).toList();

      // 3. Sort by highest score first (the most "tricky" options)
      scoredAnswers.sort((a, b) => b['score'].compareTo(a['score']));

      // 4. Take the top 5 trickiest answers, and randomly pick 3 of them
      // (We randomize the top 5 so the quiz isn't exactly the same every single time)
      List<String> topTrickiest = scoredAnswers
          .take(5)
          .map((e) => e['answer'] as String)
          .toList();
      topTrickiest.shuffle(random);
      List<String> distractors = topTrickiest.take(3).toList();

      // 5. Combine the correct answer with the 3 smart distractors
      List<String> allOptions = [...distractors, correctAnswer];

      // 6. Shuffle the final options so the correct answer isn't always 'D'
      allOptions.shuffle(random);

      quiz.add(
        QuizQuestion(
          question:
              currentCard.question, // Assuming 'question' instead of 'front'
          correctAnswer: correctAnswer,
          options: allOptions,
        ),
      );
    }

    // Optional: Shuffle the order of the questions themselves
    quiz.shuffle(random);

    return quiz;
  }

  /// THE HEURISTIC ALGORITHM
  /// Calculates how good a wrong answer is compared to the correct answer.
  /// Higher score = more confusing/better distractor.
  static int _calculateDistractorScore(String correct, String distractor) {
    int score = 0;

    // Rule 1: Number Matching (Crucial for dates, math, or statistics)
    bool correctHasNum = RegExp(r'\d').hasMatch(correct);
    bool distHasNum = RegExp(r'\d').hasMatch(distractor);
    if (correctHasNum && distHasNum) {
      score += 10; // Massive bonus if both have numbers
    } else if (!correctHasNum && !distHasNum) {
      score += 2; // Slight bonus if neither have numbers
    } else {
      score -= 5; // Penalty if one has numbers and the other doesn't
    }

    // Rule 2: Word Count Matching (Prevents mixing 1-word answers with full paragraphs)
    int correctWords = correct.trim().split(RegExp(r'\s+')).length;
    int distWords = distractor.trim().split(RegExp(r'\s+')).length;

    if (correctWords == distWords) {
      score += 5;
    } else if ((correctWords - distWords).abs() <= 2) {
      score += 3; // Good if they are within 2 words of each other
    } else if ((correctWords - distWords).abs() > 5) {
      score -= 5; // Heavy penalty if lengths are wildly different
    }

    // Rule 3: Character Length Matching (Visual similarity)
    int lengthDiff = (correct.length - distractor.length).abs();
    if (lengthDiff < 5) {
      score += 3;
    } else if (lengthDiff < 15) {
      score += 1;
    }

    return score;
  }
}
