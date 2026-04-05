import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../models/deck_model.dart';
import '../../models/card_model.dart';
import 'widgets/review_header.dart';
import 'widgets/review_progress_bar.dart';
import 'widgets/session_stats_bar.dart';
import 'widgets/flashcard_stack_view.dart';
import '../../widgets/floating_tutor_button.dart';

class ReviewScreenMobile extends StatelessWidget {
  final Deck deck;
  final List<Flashcard> reviewCards;
  final int currentIndex;
  final PageController pageController;
  final int correctCount;
  final int incorrectCount;
  final bool isBannerAdLoaded;
  final BannerAd? bannerAd;
  
  final VoidCallback onExit;
  final VoidCallback onShuffle;
  final Function(int) onPageChanged;
  final Function(bool) onFlip;
  final VoidCallback onCorrect;
  final VoidCallback onIncorrect;
  final Function(Flashcard) onExplainRequested;

  const ReviewScreenMobile({
    super.key,
    required this.deck,
    required this.reviewCards,
    required this.currentIndex,
    required this.pageController,
    required this.correctCount,
    required this.incorrectCount,
    required this.isBannerAdLoaded,
    this.bannerAd,
    required this.onExit,
    required this.onShuffle,
    required this.onPageChanged,
    required this.onFlip,
    required this.onCorrect,
    required this.onIncorrect,
    required this.onExplainRequested,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            ReviewHeader(
              currentIndex: currentIndex,
              totalCards: reviewCards.length,
              onExit: onExit,
              onShuffle: onShuffle,
            ),

            ReviewProgressBar(
              currentIndex: currentIndex,
              totalCards: reviewCards.length,
            ),

            const SizedBox(height: 12),

            SessionStatsBar(
              correctCount: correctCount,
              incorrectCount: incorrectCount,
            ),

            // 1. The Flashcard gets all the remaining vertical space
            Expanded(
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: 16),
                child: FlashcardStackView(
                  cards: reviewCards,
                  currentIndex: currentIndex,
                  pageController: pageController,
                  onPageChanged: onPageChanged,
                  onFlip: onFlip,
                  onCorrect: onCorrect,
                  onIncorrect: onIncorrect,
                  onExplainRequested: onExplainRequested,
                ),
              ),
            ),

            // 2. The Mascot sits neatly BELOW the flashcard and above the banner
            Align(
              alignment: Alignment.centerLeft,
              heightFactor: 0.5, 
              child: Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: FloatingTutorButton(deck: deck),
              ),
            ),

            const SizedBox(height: 35),
            
            // 3. Ad Banner natively sits at the absolute bottom
            if (!kIsWeb)
              SizedBox(
                height: 50,
                width: double.infinity,
                child: (isBannerAdLoaded && bannerAd != null) ? AdWidget(ad: bannerAd!) : const SizedBox.shrink(),
              ),
          ],
        ),
      ),
    );
  }
}