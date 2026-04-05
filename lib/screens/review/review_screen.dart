import 'dart:ui';
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
import '../chat/ai_chat_screen.dart'; // Import the AI Chat Screen

import 'review_screen_mobile.dart';
import 'review_screen_web.dart';

class ReviewScreen extends StatefulWidget {
  final Deck deck;
  final List<Flashcard> cards;
  final bool isShuffleOn;
  final Function(Flashcard)? onCardUpdated; // 🚀 OPTIMIZATION: Syncs state locally

  const ReviewScreen({
    super.key,
    required this.deck,
    required this.cards,
    required this.isShuffleOn,
    this.onCardUpdated,
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

  // AdMob Interstitial variables
  InterstitialAd? _interstitialAd;
  bool _isAdLoaded = false;
  bool _isFinishing = false;
  String _overlayTitle = "Saving Progress...";
  String _overlaySubtitle = "Saving your mastery progress...\nShowing an ad in the meantime ☕";
  
  // 🚀 OPTIMIZATION: Holds modified cards in memory to batch-write them later
  final Map<String, Flashcard> _pendingUpdates = {};

  // 🔙 UNDO HISTORY: Tracks previous card states and session stats
  final List<({Flashcard card, int correct, int incorrect})> _history = [];

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
    _loadInterstitialAd();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _bannerAd?.dispose(); // Clean up AdMob resources
    _interstitialAd?.dispose();
    super.dispose();
  }

  void _loadInterstitialAd() {
    if (kIsWeb) return; // Skip loading ads on web to prevent crashes

    InterstitialAd.load(
      adUnitId: AdHelper.interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isAdLoaded = true;
        },
        onAdFailedToLoad: (err) {
          debugPrint('Failed to load an interstitial ad: ${err.message}');
          _isAdLoaded = false;
        },
      ),
    );
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
          if (!mounted) {
            ad.dispose();
            return;
          }
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

  Future<void> _savePendingUpdates() async {
    if (_pendingUpdates.isNotEmpty) {
      await _cardStorageService.updateCards(_pendingUpdates.values.toList());
      _pendingUpdates.clear();
    }
  }

  void _handleAnswer(bool wasCorrect) {
    Flashcard originalCard = _reviewCards[_currentIndex];

    // 🛡️ Save the exact state before we mutate anything so we can undo it safely
    _history.add((card: originalCard, correct: _correctCount, incorrect: _incorrectCount));

    setState(() {
      if (wasCorrect) {
        if (!originalCard.isMastered) _correctCount++;
        if (originalCard.isFlagged) _incorrectCount--;
      } else {
        if (!originalCard.isFlagged) _incorrectCount++;
        if (originalCard.isMastered) _correctCount--;
      }
    });

    int quality = wasCorrect ? 4 : 0;
    
    Flashcard updatedCard = SRSService.calculateNextReview(originalCard, quality);
    
    _reviewCards[_currentIndex] = updatedCard;

    // 🚀 OPTIMIZATION: Save to memory instead of burning a Firestore write, and sync to parent
    _pendingUpdates[updatedCard.id] = updatedCard;
    widget.onCardUpdated?.call(updatedCard);

    _nextCard();
  }

  void _showInterstitialAdAndNavigate(VoidCallback onComplete) async {
    if (!kIsWeb && _isAdLoaded && _interstitialAd != null) {
      setState(() {
        _isFinishing = true;
      });
      
      await Future.delayed(const Duration(milliseconds: 1500));
      
      if (!mounted) return;
      
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _isAdLoaded = false;
          _interstitialAd = null;
          _loadInterstitialAd();
          if (mounted) {
            setState(() => _isFinishing = false);
            onComplete();
          }
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          _isAdLoaded = false;
          _interstitialAd = null;
          _loadInterstitialAd();
          if (mounted) {
            setState(() => _isFinishing = false);
            onComplete();
          }
        },
      );

      _interstitialAd!.show();
    } else {
      onComplete();
    }
  }

  void _finishReview() async {
    setState(() {
      _overlayTitle = "Saving Progress...";
      _overlaySubtitle = "Saving your mastery progress...\nShowing an ad in the meantime ☕";
    });
    await _savePendingUpdates(); // 🚀 Batch write all progress at once
    _showInterstitialAdAndNavigate(_navigateToCompletion);
  }

  void _navigateToCompletion() {
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

  void _undo() {
    if (_history.isEmpty || _currentIndex == 0) return;
    HapticFeedback.lightImpact();

    final lastState = _history.removeLast();

    setState(() {
      _currentIndex--;
      _showAnswer = false; 
      _correctCount = lastState.correct;
      _incorrectCount = lastState.incorrect;
      _reviewCards[_currentIndex] = lastState.card;

      _pendingUpdates.remove(lastState.card.id);
      widget.onCardUpdated?.call(lastState.card);
    });

    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _handleShuffle() {
    setState(() {
      _reviewCards.shuffle();
      _currentIndex = 0;
      _showAnswer = false;
      _history.clear(); // Clear history to prevent jumping to an invalid state
    });
    _pageController.jumpToPage(0);
  }

  void _handleExplainRequested(Flashcard card) async {
    HapticFeedback.lightImpact();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final proceed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.auto_awesome_rounded, color: Color(0xFF8B4EFF)),
            const SizedBox(width: 8),
            Text("Ask AI Tutor", style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color)),
          ],
        ),
        content: Text(
          "The AI Tutor will explain this flashcard in detail. This will consume 1 AI Energy.",
          style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B4EFF),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("Ask AI", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (proceed != true) return;

    setState(() {
      _overlayTitle = "Passing question to AI...";
      _overlaySubtitle = "Watch an ad in the meantime ☕";
    });

    _showInterstitialAdAndNavigate(() {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AIChatScreen(
            deck: widget.deck,
            initialPrompt: "Can you explain this flashcard to me in simple terms?\n\nQuestion: ${card.question}\nAnswer: ${card.answer}",
          ),
        ),
      );
    });
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
      child: PopScope(
        canPop: true,
        onPopInvokedWithResult: (didPop, _) {
          // 🚀 Catch system back button to ensure we don't lose progress
          _savePendingUpdates(); 
        },
        child: Stack(
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final isDesktop = constraints.maxWidth >= 850;
  
                if (isDesktop) {
                  return ReviewScreenWeb(
                    deck: widget.deck,
                    reviewCards: _reviewCards,
                    currentIndex: _currentIndex,
                    pageController: _pageController,
                    correctCount: _correctCount,
                    incorrectCount: _incorrectCount,
                    canUndo: _history.isNotEmpty,
                    onUndo: _undo,
                    onExit: () {
                      _savePendingUpdates();
                      Navigator.pop(context);
                    },
                    onShuffle: _handleShuffle,
                    onPageChanged: (index) => setState(() { _currentIndex = index; _showAnswer = false; }),
                    onFlip: (isFront) => setState(() => _showAnswer = !isFront),
                    onCorrect: () => _handleAnswer(true),
                    onIncorrect: () => _handleAnswer(false),
                    onExplainRequested: _handleExplainRequested,
                  );
                } else {
                  return ReviewScreenMobile(
                    deck: widget.deck,
                    reviewCards: _reviewCards,
                    currentIndex: _currentIndex,
                    pageController: _pageController,
                    correctCount: _correctCount,
                    incorrectCount: _incorrectCount,
                    isBannerAdLoaded: _isBannerAdLoaded,
                    bannerAd: _bannerAd,
                    canUndo: _history.isNotEmpty,
                    onUndo: _undo,
                    onExit: () {
                      _savePendingUpdates();
                      Navigator.pop(context);
                    },
                    onShuffle: _handleShuffle,
                    onPageChanged: (index) => setState(() { _currentIndex = index; _showAnswer = false; }),
                    onFlip: (isFront) => setState(() => _showAnswer = !isFront),
                    onCorrect: () => _handleAnswer(true),
                    onIncorrect: () => _handleAnswer(false),
                    onExplainRequested: _handleExplainRequested,
                  );
                }
              },
            ),
            if (_isFinishing)
              Positioned.fill(
                child: Material(
                  color: Colors.transparent,
                  child: ClipRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                      child: Container(
                        color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.85),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 60,
                              height: 60,
                              child: CircularProgressIndicator(
                                color: Color(0xFF8B4EFF),
                                strokeWidth: 4,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              _overlayTitle,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: Theme.of(context).textTheme.bodyLarge?.color,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _overlaySubtitle,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 15,
                                color: isDark ? Colors.white70 : Colors.grey.shade700,
                                height: 1.4,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}