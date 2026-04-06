import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart'; // Required for kIsWeb
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart'; // Required for AdMob
import 'package:audioplayers/audioplayers.dart';
import 'package:confetti/confetti.dart';
import '../../models/quiz_question_model.dart';
import '../../services/ad_helper.dart'; // AdHelper for Unit IDs
import '../../services/pro_service.dart'; // Required to check Pro status for the banner
import '../../services/deck_storage_service.dart'; // Required to fetch the deck
import '../chat/ai_chat_screen.dart'; // Required to open the AI Chat
import 'quiz_mobile.dart';
import 'quiz_web.dart';

class QuizScreen extends StatefulWidget {
  final List<QuizQuestion> quiz;
  final String deckTitle;
  final String deckId; // 🛡️ BUG FIX: Require unique deckId to prevent progress collisions

  const QuizScreen({super.key, required this.quiz, required this.deckTitle, required this.deckId});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int _currentIndex = 0;
  late List<String?> _answers;

  // Debounce timer
  Timer? _saveDebounce;

  // AdMob Interstitial variables
  InterstitialAd? _interstitialAd;
  bool _isAdLoaded = false;

  // AdMob Banner variables
  BannerAd? _bannerAd;
  bool _isBannerAdLoaded = false;

  // Audio Player for feedback sounds
  final AudioPlayer _audioPlayer = AudioPlayer();

  // Confetti controller for perfect score
  late ConfettiController _confettiController;

  bool _canPop = false;
  bool _isFinishing = false; // Controls the loading overlay
  String _overlayTitle = "Calculating Score...";
  String _overlaySubtitle = "Wrapping up your quiz results.\nShowing an ad in the meantime ☕";

  @override
  void initState() {
    super.initState();
    _answers = List.filled(widget.quiz.length, null);
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _loadProgress();
    _loadInterstitialAd();
    _loadBannerAd(); // Safely load the banner ad for Free users
  }

  @override
  void dispose() {
    _saveDebounce?.cancel();
    if (!_canPop) {
      _flushSave();
    }
    _interstitialAd?.dispose();
    _bannerAd?.dispose();
    _audioPlayer.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  void _loadBannerAd() {
    if (kIsWeb) return;
    if (ProService().isPro) return;

    final adUnitId = AdHelper.bannerAdUnitId;
    if (adUnitId.isEmpty) return;

    _bannerAd = BannerAd(
      adUnitId: adUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          setState(() {
            _isBannerAdLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          debugPrint('BannerAd failed to load: $error');
        },
      ),
    )..load();
  }

  void _loadInterstitialAd() {
    if (kIsWeb) return;

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

  bool get _hasAnsweredCurrent => _answers[_currentIndex] != null;
  String? get _selectedAnswerCurrent => _answers[_currentIndex];

  int get _correctCount {
    int count = 0;
    for (int i = 0; i < widget.quiz.length; i++) {
      if (_answers[i] == widget.quiz[i].correctAnswer) count++;
    }
    return count;
  }

  int get _incorrectCount {
    int count = 0;
    for (int i = 0; i < widget.quiz.length; i++) {
      if (_answers[i] != null && _answers[i] != widget.quiz[i].correctAnswer) {
        count++;
      }
    }
    return count;
  }

  int get _remainingCount =>
      widget.quiz.length - _answers.where((a) => a != null).length;

  void _scheduleSave() {
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 800), _flushSave);
  }

  Future<void> _flushSave() async {
    final prefs = await SharedPreferences.getInstance();
    final savedAnswers = _answers.map((e) => e ?? '').toList();
    await prefs.setStringList('quiz_answers_${widget.deckId}', savedAnswers);
    await prefs.setInt('quiz_index_${widget.deckId}', _currentIndex);
  }

  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final savedAnswers =
        prefs.getStringList('quiz_answers_${widget.deckId}');
    final savedIndex = prefs.getInt('quiz_index_${widget.deckId}');

    if (savedAnswers != null && savedAnswers.length == widget.quiz.length) {
      setState(() {
        _answers = savedAnswers.map((e) => e.isEmpty ? null : e).toList();
        _currentIndex = savedIndex ?? 0;
      });
    }
  }

  Future<void> _clearProgress() async {
    _saveDebounce?.cancel();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('quiz_answers_${widget.deckId}');
    await prefs.remove('quiz_index_${widget.deckId}');
  }

  void _checkAnswer(String answer) async {
    if (_hasAnsweredCurrent) return;
    HapticFeedback.lightImpact();
    
    setState(() {
      _answers[_currentIndex] = answer;
    });

    try {
      final isCorrect = answer == widget.quiz[_currentIndex].correctAnswer;
      if (isCorrect) {
        await _audioPlayer.play(AssetSource('sounds/correct.mp3'));
      } else {
        await _audioPlayer.play(AssetSource('sounds/incorrect.mp3'));
      }
    } catch (e) {
      debugPrint("Audio playback error: $e");
    }

    _scheduleSave();
  }

  void _nextQuestion() {
    if (_currentIndex < widget.quiz.length - 1) {
      setState(() => _currentIndex++);
      _scheduleSave();
    } else {
      _showResults();
    }
  }

  void _previousQuestion() {
    if (_currentIndex > 0) {
      setState(() => _currentIndex--);
      _scheduleSave();
    }
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

  void _handleExplainRequested(QuizQuestion question, String? selectedAnswer) async {
    HapticFeedback.lightImpact();
    
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
          "The AI Tutor will explain this question and its answer in detail. This will consume 1 AI Energy.",
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

    try {
      final decks = await DeckStorageService().getDecks();
      final deck = decks.firstWhere((d) => d.id == widget.deckId);
      
      if (!mounted) return;
      
      String prompt = "Can you explain this quiz question to me?\n\nQuestion: ${question.question}\nCorrect Answer: ${question.correctAnswer}";
      if (selectedAnswer != null && selectedAnswer != question.correctAnswer) {
        prompt = "I got this quiz question wrong. I guessed '$selectedAnswer', but the correct answer is '${question.correctAnswer}'. Can you explain why?\n\nQuestion: ${question.question}";
      }
      
      setState(() {
        _overlayTitle = "Passing question to AI...";
        _overlaySubtitle = "Watch an ad in the meantime ☕";
      });

      _showInterstitialAdAndNavigate(() {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AIChatScreen(
              deck: deck,
              initialPrompt: prompt,
            ),
          ),
        );
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error launching AI Tutor.")));
    }
  }

  Future<bool> _onWillPop() async {
    _saveDebounce?.cancel();
    if (!_canPop) {
      await _flushSave();
    }
    
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Pause Quiz?',
          style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color),
        ),
        content: Text(
          'Your progress has been automatically saved. You can resume later.',
          style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? const Color(0xFF8B4EFF).withValues(alpha: 0.2) : const Color(0xFF8B4EFF).withValues(alpha: 0.1),
              foregroundColor: isDark ? const Color(0xFFB48AFF) : const Color(0xFF8B4EFF),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Exit',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
    return shouldPop ?? false;
  }

  void _handlePopInvoked(bool didPop, dynamic result) async {
    if (didPop) return;
    final shouldPop = await _onWillPop();
    if (shouldPop && mounted) {
      setState(() {
        _canPop = true;
      });
      Future.microtask(() {
        if (mounted) Navigator.of(context).pop();
      });
    }
  }

  void _handleClose() async {
    if (_canPop) {
      Navigator.of(context).pop();
      return;
    }
    final shouldPop = await _onWillPop();
    if (shouldPop && mounted) {
      setState(() => _canPop = true);
      Future.microtask(() { if (mounted) Navigator.of(context).pop(); });
    }
  }

  void _showResults() async {
    setState(() {
      _canPop = true;
      _overlayTitle = "Calculating Score...";
      _overlaySubtitle = "Wrapping up your quiz results.\nShowing an ad in the meantime ☕";
    });
    await _clearProgress();
    if (!mounted) return;

    _showInterstitialAdAndNavigate(_showResultsDialog);
  }

  void _showResultsDialog() {
    if (!mounted) return;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isPerfectScore = _correctCount == widget.quiz.length;
    
    if (isPerfectScore) {
      _confettiController.play();
      try {
        _audioPlayer.play(AssetSource('sounds/correct.mp3')); // Plays victory sound
      } catch (e) {
        debugPrint("Audio playback error: $e");
      }
    }
    
    final LinearGradient brandGradient = const LinearGradient(
      colors: [Color(0xFF8B4EFF), Color(0xFFE841A1)],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        elevation: 20,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: brandGradient,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: const Color(0xFF8B4EFF).withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 10))
                      ],
                    ),
                    child: const Icon(
                      Icons.emoji_events_rounded,
                      color: Colors.white,
                      size: 64,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    isPerfectScore ? 'Perfect Score! 🏆' : 'Quiz Complete!',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 28, letterSpacing: -0.5, color: Theme.of(context).textTheme.bodyLarge?.color),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'You scored $_correctCount out of ${widget.quiz.length} correctly.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16, 
                      color: isDark ? Colors.white70 : Colors.grey.shade700,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context); // close dialog
                        Navigator.pop(context); // close screen
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B4EFF),
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Return to Deck',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (isPerfectScore)
              Align(
                alignment: Alignment.topCenter,
                child: ConfettiWidget(
                  confettiController: _confettiController,
                  blastDirectionality: BlastDirectionality.explosive,
                  shouldLoop: false,
                  emissionFrequency: 0.05,
                  numberOfParticles: 30,
                  maxBlastForce: 100,
                  minBlastForce: 80,
                  colors: const [
                    Color(0xFF8B4EFF),
                    Color(0xFFE841A1),
                    Colors.amber,
                    Colors.greenAccent,
                    Colors.lightBlueAccent,
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 850;
        
        if (isDesktop) {
          return QuizWeb(
            quiz: widget.quiz,
            deckTitle: widget.deckTitle,
            currentIndex: _currentIndex,
            answers: _answers,
            hasAnsweredCurrent: _hasAnsweredCurrent,
            selectedAnswerCurrent: _selectedAnswerCurrent,
            correctCount: _correctCount,
            incorrectCount: _incorrectCount,
            remainingCount: _remainingCount,
            isFinishing: _isFinishing,
            overlayTitle: _overlayTitle,
            overlaySubtitle: _overlaySubtitle,
            canPop: _canPop,
            onCheckAnswer: _checkAnswer,
            onNextQuestion: _nextQuestion,
            onPreviousQuestion: _previousQuestion,
            onPopInvoked: _handlePopInvoked,
            onClose: _handleClose,
            onExplainRequested: _handleExplainRequested,
          );
        } else {
          return QuizMobile(
            quiz: widget.quiz,
            deckTitle: widget.deckTitle,
            currentIndex: _currentIndex,
            answers: _answers,
            hasAnsweredCurrent: _hasAnsweredCurrent,
            selectedAnswerCurrent: _selectedAnswerCurrent,
            correctCount: _correctCount,
            incorrectCount: _incorrectCount,
            remainingCount: _remainingCount,
            isFinishing: _isFinishing,
            overlayTitle: _overlayTitle,
            overlaySubtitle: _overlaySubtitle,
            bannerAd: _bannerAd,
            isBannerAdLoaded: _isBannerAdLoaded,
            canPop: _canPop,
            onCheckAnswer: _checkAnswer,
            onNextQuestion: _nextQuestion,
            onPreviousQuestion: _previousQuestion,
            onPopInvoked: _handlePopInvoked,
            onClose: _handleClose,
            onExplainRequested: _handleExplainRequested,
          );
        }
      },
    );
  }
}
