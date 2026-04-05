import 'dart:math';
import '../models/card_model.dart';

class SRSService {
  static Flashcard calculateNextReview(Flashcard card, int quality) {
    int updatedRepetitions = card.repetitions;
    double updatedEaseFactor = card.easeFactor;
    int updatedInterval = card.interval;

    if (quality < 3) {
      updatedRepetitions = 0;
      updatedInterval = 1;
    } else {
      if (updatedRepetitions == 0) {
        updatedInterval = 1; 
      } else if (updatedRepetitions == 1) {
        updatedInterval = 6; 
      } else {
        updatedInterval = (updatedInterval * updatedEaseFactor).round();
      }
      updatedRepetitions++;
    }

    updatedEaseFactor = updatedEaseFactor + (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02));
    
    if (updatedEaseFactor < 1.3) {
      updatedEaseFactor = 1.3;
    } else if (updatedEaseFactor > 3.0) {
      // 🚀 EFFICIENCY: Cap maximum ease factor to prevent intervals from growing 
      // exponentially out of control for easy cards.
      updatedEaseFactor = 3.0;
    }

    // 🚀 EFFICIENCY: Enforce a maximum interval (e.g., 1 year) so cards are never lost forever
    if (updatedInterval > 365) {
      updatedInterval = 365;
    }

    // 🚀 EFFICIENCY: Apply "Fuzzing" to prevent Review Spikes.
    // If multiple cards are studied today and get the same multiplier, fuzzing spreads 
    // them out by a few days so they don't all clump together on the exact same future date.
    if (updatedInterval > 3) {
      final random = Random();
      // Fuzz by roughly ±5% (minimum 1 day, max 14 days)
      final fuzzRange = (updatedInterval * 0.05).ceil().clamp(1, 14);
      final fuzz = random.nextInt(fuzzRange * 2 + 1) - fuzzRange;
      updatedInterval += fuzz;
    }

    DateTime nextDate = DateTime.now().add(Duration(days: updatedInterval));

    return card.copyWith(
      repetitions: updatedRepetitions,
      easeFactor: updatedEaseFactor,
      interval: updatedInterval,
      nextReviewDate: nextDate,
      // Record exactly what they pressed so we can show the indicator next time!
      lastScore: quality, 
      isMastered: quality >= 4,
      isFlagged: quality < 3,
    );
  }
}