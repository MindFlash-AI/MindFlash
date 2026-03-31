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