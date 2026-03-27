import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/deck_model.dart';
import '../../models/card_model.dart';
import '../../services/card_storage_service.dart';
import 'review_completion.dart';

import 'widgets/review_header.dart';
import 'widgets/review_progress_bar.dart';
import 'widgets/session_stats_bar.dart';
import 'widgets/flashcard_stack_view.dart';
import 'widgets/review_action_buttons.dart';

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
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
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

    // 💡 FIX: AnnotatedRegion forces the status bar icons to be DARK (black).
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent, // Ensures it doesn't add a weird solid block
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFFDF9FF),
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

              Expanded(
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(top: 16),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF8B4EFF), Color(0xFFE841A1)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        child: FlashcardStackView(
                          cards: _reviewCards,
                          currentIndex: _currentIndex,
                          pageController: _pageController,
                          onPageChanged: (index) {
                            setState(() {
                              _currentIndex = index;
                              _showAnswer = false; // Reset answer state when swiping
                            });
                          },
                          onFlip: (isFront) {
                            setState(() {
                              _showAnswer = !isFront;
                            });
                          },
                        ),
                      ),
                      ReviewActionButtons(
                        showAnswer: _showAnswer,
                        onCorrect: () => _handleAnswer(true),
                        onIncorrect: () => _handleAnswer(false),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}