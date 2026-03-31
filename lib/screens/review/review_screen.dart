import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart'; // Required for kIsWeb
import 'package:google_mobile_ads/google_mobile_ads.dart'; // Required for AdMob

import '../../models/deck_model.dart';
import '../../models/card_model.dart';
import '../../services/card_storage_service.dart';
import '../../services/ad_helper.dart'; // AdHelper for Unit IDs
import '../../services/srs_service.dart'; // SRS Math Engine
import 'review_completion.dart';

import 'widgets/review_header.dart';
import 'widgets/review_progress_bar.dart';
import 'widgets/session_stats_bar.dart';
import 'widgets/flashcard_stack_view.dart';
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
  final CardStorageService _cardStorageService = CardStorageService();

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
    // Grab the card BEFORE it gets updated by the SRS math
    Flashcard originalCard = _reviewCards[_currentIndex];

    // --- ORIGINAL STATS LOGIC ---
    // We update the session stats *first* based on the old card state 
    // to ensure the UI updates perfectly in real-time!
    setState(() {
      if (wasCorrect) {
        if (!originalCard.isMastered) _correctCount++;
        if (originalCard.isFlagged) _incorrectCount--;
      } else {
        if (!originalCard.isFlagged) _incorrectCount++;
        if (originalCard.isMastered) _correctCount--;
      }
    });

    // --- NEW SRS LOGIC ---
    // Map boolean to SRS quality score quietly in the background
    int quality = wasCorrect ? 4 : 0;
    
    // Process the card through the math engine (this sets isMastered/isFlagged internally)
    Flashcard updatedCard = SRSService.calculateNextReview(originalCard, quality);
    
    // Update local list to sync UI
    _reviewCards[_currentIndex] = updatedCard;

    // Save to local storage and move to next card
    _cardStorageService.updateCard(updatedCard);
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
                    // Handlers passed into the contextual action buttons
                    onCorrect: () => _handleAnswer(true),
                    onIncorrect: () => _handleAnswer(false),
                  ),
                ),
              ),

              // 2. The Mascot sits neatly BELOW the flashcard and above the banner
              Align(
                alignment: Alignment.centerLeft,
                heightFactor: 0.5, 
                child: Padding(
                  padding: const EdgeInsets.only(left: 16.0),
                  child: FloatingTutorButton(deck: widget.deck),
                ),
              ),

              const SizedBox(height: 35),
              
              // 3. Ad Banner natively sits at the absolute bottom
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