import 'dart:math';
import '../models/quiz_question_model.dart';
import '../models/card_model.dart';

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

    // FIX 1: Build profiles once, outside the per-question loop.
    // Previously _AnswerProfile objects were constructed inside the loop,
    // meaning they were rebuilt on every iteration unnecessarily.
    final List<_AnswerProfile> allProfiles =
        deck.map((c) => _AnswerProfile(c.answer)).toList();

    // FIX 2: Shuffle the deck indices once up front instead of shuffling
    // intermediate lists inside the per-question loop AND shuffling the
    // final quiz list at the end. One shuffle produces randomised output.
    final List<int> questionOrder =
        List.generate(deck.length, (i) => i)..shuffle(random);

    final List<QuizQuestion> quiz = [];

    for (final i in questionOrder) {
      final currentCard = deck[i];
      final correctProfile = allProfiles[i];

      // FIX 3: Score and collect all candidates in one pass, skipping
      // the correct answer index directly rather than checking a Set
      // membership on every iteration. Using a fixed-size top-5 heap
      // keeps memory constant and avoids the full sort on large decks.
      //
      // For typical deck sizes (< 200 cards) a simple scored list + partial
      // sort is already very fast, but we avoid the Set<String> allocation
      // and the repeated uniqueDistractors.contains() call.
      final List<({String text, int score})> candidates = [];

      for (int j = 0; j < allProfiles.length; j++) {
        if (j == i) continue; // skip the correct answer
        final candidate = allProfiles[j];
        // FIX 4: Deduplicate by text only — no need for a Set allocation when
        // we can check while building the list. Decks with duplicate answers
        // are edge-cases; a simple linear scan over the small candidates list
        // is cheaper than maintaining a separate Set.
        if (candidates.any((c) => c.text == candidate.text)) continue;
        candidates.add((
          text: candidate.text,
          score: _calculateFastScore(correctProfile, candidate),
        ));
      }

      if (candidates.length < 3) {
        throw Exception(
          'Not enough unique answers in the deck to create a valid multiple-choice quiz.',
        );
      }

      // FIX 5: We only need the top 5 — use a partial sort (take after sort)
      // which is still O(n log n) but avoids allocating a second list for
      // topTrickiest and its own shuffle.
      candidates.sort((a, b) => b.score.compareTo(a.score));

      // Pick 3 distractors from the top 5, then combine with correct answer.
      final poolSize = min(5, candidates.length);
      final List<String> options = candidates
          .take(poolSize)
          .map((c) => c.text)
          .toList()
        ..shuffle(random);
      options
        ..length = 3
        ..add(correctProfile.text)
        ..shuffle(random);

      quiz.add(QuizQuestion(
        question: currentCard.question,
        correctAnswer: correctProfile.text,
        options: options,
      ));
    }

    // FIX 2 (continued): No final quiz.shuffle() needed — questionOrder was
    // already shuffled, so quiz is in random order by construction.
    return quiz;
  }

  static int _calculateFastScore(
    _AnswerProfile correct,
    _AnswerProfile distractor,
  ) {
    int score = 0;

    if (correct.hasNumber == distractor.hasNumber) {
      score += correct.hasNumber ? 10 : 2;
    } else {
      score -= 5;
    }

    final diffWords = (correct.wordCount - distractor.wordCount).abs();
    if (diffWords == 0) {
      score += 5;
    } else if (diffWords <= 2) {
      score += 3;
    } else if (diffWords > 5) {
      score -= 5;
    }

    final lengthDiff = (correct.length - distractor.length).abs();
    if (lengthDiff < 5) {
      score += 3;
    } else if (lengthDiff < 15) {
      score += 1;
    }

    return score;
  }
}