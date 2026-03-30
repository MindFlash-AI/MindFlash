import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart'; // Required for kIsWeb
import 'package:google_mobile_ads/google_mobile_ads.dart'; // Required for AdMob

import '../../models/deck_model.dart';
import '../../models/card_model.dart';
import '../../services/card_storage_service.dart';
import '../../services/ad_helper.dart'; // AdHelper for Unit IDs
import 'review_completion.dart';

import 'widgets/review_header.dart';
import 'widgets/review_progress_bar.dart';
import 'widgets/session_stats_bar.dart';
import 'widgets/flashcard_stack_view.dart';
import 'widgets/review_action_buttons.dart';
import '../../widgets/floating_tutor_button.dart'; // Mascot Button Import

class ReviewScreen extends StatefulWidget {
  final Deck deck;
  final List<Flashcard> cards;
  final bool isShuffleOn;

  const ReviewScreen({
    super.key,
    required this.deck,
    required this.cards,
    required this.isShuffleOn,
  });

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  final ICardStorageService _cardStorageService = CardStorageService();

  late List<Flashcard> _reviewCards;
  late PageController _pageController;
  int _currentIndex = 0;
  bool _showAnswer = false;
  int _correctCount = 0;
  int _incorrectCount = 0;

  // AdMob Banner variables
  BannerAd? _bannerAd;
  bool _isBannerAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    
    _reviewCards = List.from(widget.cards);

    _correctCount = _reviewCards.where((c) => c.isMastered).length;
    _incorrectCount = _reviewCards.where((c) => c.isFlagged).length;

    if (widget.isShuffleOn) {
      _reviewCards.shuffle();
    }

    // Initialize Banner Ad
    _loadBannerAd();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _bannerAd?.dispose(); // Clean up AdMob resources
    super.dispose();
  }

  // Load Banner Ad
  void _loadBannerAd() {
    if (kIsWeb) return; // Skip loading ads on web to prevent crashes

    _bannerAd = BannerAd(
      adUnitId: AdHelper.bannerAdUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          setState(() {
            _isBannerAdLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, err) {
          debugPrint('Failed to load a banner ad: ${err.message}');
          ad.dispose();
        },
      ),
    )..load();
  }

  void _nextCard() {
    if (_currentIndex < _reviewCards.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finishReview();
    }
  }

  void _previousCard() {
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _handleAnswer(bool wasCorrect) {
    Flashcard currentCard = _reviewCards[_currentIndex];

    if (wasCorrect) {
      if (!currentCard.isMastered) _correctCount++;
      if (currentCard.isFlagged) _incorrectCount--;

      currentCard.isMastered = true;
      currentCard.isFlagged = false;
    } else {
      if (!currentCard.isFlagged) _incorrectCount++;
      if (currentCard.isMastered) _correctCount--;

      currentCard.isFlagged = true;
      currentCard.isMastered = false;
    }

    _cardStorageService.updateCard(currentCard);
    _nextCard();
  }

  void _finishReview() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ReviewCompletionScreen(
          deck: widget.deck,
          totalCards: _currentIndex + 1,
          allCards: widget.cards,
          correctCards: _correctCount,
        ),
      ),
    );
  }

  void _handleShuffle() {
    setState(() {
      _reviewCards.shuffle();
      _currentIndex = 0;
      _showAnswer = false;
    });
    _pageController.jumpToPage(0);
  }

  @override
  Widget build(BuildContext context) {
    if (_reviewCards.isEmpty) return const Scaffold();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ) : SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: Column(
            children: [
              ReviewHeader(
                currentIndex: _currentIndex,
                totalCards: _reviewCards.length,
                onExit: () => Navigator.pop(context),
                onShuffle: _handleShuffle,
              ),

              ReviewProgressBar(
                currentIndex: _currentIndex,
                totalCards: _reviewCards.length,
              ),

              const SizedBox(height: 12),

              SessionStatsBar(
                correctCount: _correctCount,
                incorrectCount: _incorrectCount,
              ),

              // 1. The Flashcard gets all the remaining vertical space
              Expanded(
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(top: 16),
                  child: FlashcardStackView(
                    cards: _reviewCards,
                    currentIndex: _currentIndex,
                    pageController: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        _currentIndex = index;
                        _showAnswer = false; 
                      });
                    },
                    onFlip: (isFront) {
                      setState(() {
                        _showAnswer = !isFront;
                      });
                    },
                  ),
                ),
              ),

              // 2. The Mascot sits neatly BELOW the flashcard and above the buttons
              // We use an Align with heightFactor to gracefully collapse the invisible negative space 
              // left behind when we translated the mascot upward in its own file!
              Align(
                alignment: Alignment.centerLeft,
                heightFactor: 0.5, 
                child: Padding(
                  padding: const EdgeInsets.only(left: 16.0),
                  child: FloatingTutorButton(deck: widget.deck),
                ),
              ),

              // 3. Action Buttons have their own dedicated space
              // Removed the extra top padding to pull it perfectly flush with the mascot
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: ReviewActionButtons(
                  showAnswer: _showAnswer,
                  onCorrect: () => _handleAnswer(true),
                  onIncorrect: () => _handleAnswer(false),
                ),
              ),
              
              // 4. Ad Banner natively sits at the absolute bottom
              // Fixed 50px space reservation to prevent layout jump!
              if (!kIsWeb)
                SizedBox(
                  height: 50,
                  width: double.infinity,
                  child: (_isBannerAdLoaded && _bannerAd != null)
                      ? AdWidget(ad: _bannerAd!)
                      : const SizedBox.shrink(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}