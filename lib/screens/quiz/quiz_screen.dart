import 'dart:async';
import 'dart:ui'; // Required for ImageFilter (BackdropFilter)
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart'; // Required for kIsWeb
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart'; // Required for AdMob
import '../../models/quiz_question_model.dart';
import '../../services/ad_helper.dart'; // AdHelper for Unit IDs
import '../../services/pro_service.dart'; // Required to check Pro status for the banner

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

  // Debounce timer — instead of writing to SharedPreferences on every
  // answer and every navigation tap (up to 40 writes for a 20-question quiz),
  // we schedule a write 800 ms after the last state change. If the user taps
  // quickly through questions, intermediate states are skipped entirely.
  Timer? _saveDebounce;

  // AdMob Interstitial variables
  InterstitialAd? _interstitialAd;
  bool _isAdLoaded = false;

  // AdMob Banner variables
  BannerAd? _bannerAd;
  bool _isBannerAdLoaded = false;

  bool _canPop = false;
  bool _isFinishing = false; // Controls the loading overlay

  final LinearGradient _brandGradient = const LinearGradient(
    colors: [Color(0xFF8B4EFF), Color(0xFFE841A1)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  @override
  void initState() {
    super.initState();
    _answers = List.filled(widget.quiz.length, null);
    _loadProgress();
    _loadInterstitialAd();
    _loadBannerAd(); // Safely load the banner ad for Free users
  }

  @override
  void dispose() {
    // Flush any pending debounced save immediately on dispose so progress
    // is never lost when the user backgrounds the app mid-quiz.
    _saveDebounce?.cancel();
    if (!_canPop) {
      _flushSave();
    }
    _interstitialAd?.dispose(); // Clean up AdMob resources
    _bannerAd?.dispose(); // Clean up Banner Ad resources
    super.dispose();
  }

  void _loadBannerAd() {
    if (kIsWeb) return;
    if (ProService().isPro) return; // Pro users do not get banners

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
    if (kIsWeb) return; // Skip loading ads on web to prevent crashes

    InterstitialAd.load(
      adUnitId: AdHelper.interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              if (mounted) {
                setState(() => _isFinishing = false);
                _showResultsDialog(); // Show results after ad is dismissed
              }
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              if (mounted) {
                setState(() => _isFinishing = false);
                _showResultsDialog(); // Show results even if ad fails to display
              }
            },
          );
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

  // Schedules a debounced save. Only the final state within the 800 ms
  // window is persisted, collapsing many rapid taps into a single write.
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
    _saveDebounce?.cancel(); // discard any pending debounced save
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('quiz_answers_${widget.deckId}');
    await prefs.remove('quiz_index_${widget.deckId}');
  }

  void _checkAnswer(String answer) {
    if (_hasAnsweredCurrent) return;
    HapticFeedback.lightImpact();
    setState(() {
      _answers[_currentIndex] = answer;
    });
    _scheduleSave(); // debounced, not immediate
  }

  void _nextQuestion() {
    if (_currentIndex < widget.quiz.length - 1) {
      setState(() => _currentIndex++);
      _scheduleSave(); // debounced
    } else {
      _showResults();
    }
  }

  void _previousQuestion() {
    if (_currentIndex > 0) {
      setState(() => _currentIndex--);
      _scheduleSave(); // debounced
    }
  }

  Future<bool> _onWillPop() async {
    // Flush immediately so progress is saved before the screen is popped.
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
              backgroundColor: isDark ? const Color(0xFF8B4EFF).withOpacity(0.2) : const Color(0xFF8B4EFF).withOpacity(0.1),
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

  void _showResults() async {
    setState(() {
      _canPop = true;
    });
    await _clearProgress();
    if (!mounted) return;

    if (!kIsWeb && _isAdLoaded && _interstitialAd != null) {
      setState(() {
        _isFinishing = true; // Show the blurred overlay
      });
      
      // Delay for 1.5 seconds to let the user read the overlay text
      await Future.delayed(const Duration(milliseconds: 1500));
      
      if (!mounted) return;
      _interstitialAd!.show();
      _isAdLoaded = false;
    } else {
      _showResultsDialog();
    }
  }

  void _showResultsDialog() {
    if (!mounted) return;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Quiz Complete!',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A1128) : const Color(0xFFF9F5FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.emoji_events,
                color: Color(0xFF8B4EFF),
                size: 48,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'You scored $_correctCount out of ${widget.quiz.length}.',
              style: TextStyle(
                fontSize: 18, 
                fontWeight: FontWeight.w600,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B4EFF),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Return to Deck',
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBadge(IconData icon, Color color, String text) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar(double progress, bool isDark) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: progress),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) => Container(
        height: 6,
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: isDark ? Colors.white12 : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(3),
        ),
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: value,
          child: Container(
            decoration: BoxDecoration(
              gradient: _brandGradient,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStatBadge(
            Icons.check_circle_rounded,
            isDark ? Colors.greenAccent.shade400 : Colors.green.shade600,
            '$_correctCount',
          ),
          _buildStatBadge(
            Icons.cancel_rounded,
            isDark ? Colors.redAccent.shade200 : Colors.red.shade500,
            '$_incorrectCount',
          ),
          _buildStatBadge(
            Icons.help_outline_rounded,
            isDark ? Colors.white54 : Colors.grey.shade500,
            '$_remainingCount',
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(QuizQuestion currentQuestion, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: isDark ? Border.all(color: Colors.white.withOpacity(0.05)) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Center(
        child: SingleChildScrollView(
          child: Text(
            currentQuestion.question,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.bodyLarge?.color,
              height: 1.4,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOptionsList(QuizQuestion currentQuestion, bool isDark) {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      itemCount: currentQuestion.options.length,
      itemBuilder: (context, index) {
        final option = currentQuestion.options[index];
        Color buttonColor = Theme.of(context).cardColor;
        Color textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87;
        Color borderColor = Colors.transparent;
        IconData? feedbackIcon;
        Color iconColor = Colors.transparent;

        if (_hasAnsweredCurrent) {
          if (option == currentQuestion.correctAnswer) {
            buttonColor = isDark ? Colors.green.withOpacity(0.2) : Colors.green.shade50;
            borderColor = isDark ? Colors.greenAccent : Colors.green.shade400;
            textColor = isDark ? Colors.greenAccent : Colors.green.shade800;
            feedbackIcon = Icons.check_circle_rounded;
            iconColor = isDark ? Colors.greenAccent : Colors.green.shade500;
          } else if (option == _selectedAnswerCurrent) {
            buttonColor = isDark ? Colors.red.withOpacity(0.2) : Colors.red.shade50;
            borderColor = isDark ? Colors.redAccent : Colors.red.shade400;
            textColor = isDark ? Colors.redAccent : Colors.red.shade800;
            feedbackIcon = Icons.cancel_rounded;
            iconColor = isDark ? Colors.redAccent : Colors.red.shade500;
          }
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: InkWell(
            onTap: () => _checkAnswer(option),
            borderRadius: BorderRadius.circular(16),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: buttonColor,
                border: Border.all(color: borderColor, width: 2),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.3 : 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      option,
                      style: TextStyle(
                        fontSize: 16,
                        color: textColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (feedbackIcon != null)
                    Icon(feedbackIcon, color: iconColor, size: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavigationButtons(bool isDark) {
    return Row(
      children: [
        if (_currentIndex > 0)
          Expanded(
            flex: 1,
            child: OutlinedButton(
              onPressed: _previousQuestion,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                side: BorderSide(color: isDark ? Colors.white24 : Colors.grey.shade300, width: 2),
              ),
              child: Text(
                'Previous',
                style: TextStyle(
                  fontSize: 16,
                  color: isDark ? Colors.white70 : Colors.grey.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        if (_currentIndex > 0 && _hasAnsweredCurrent) const SizedBox(width: 12),
        if (_hasAnsweredCurrent)
          Expanded(
            flex: 2,
            child: Container(
              decoration: BoxDecoration(
                gradient: _brandGradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: const Color(0xFF8B4EFF).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 6)),
                ],
              ),
              child: ElevatedButton(
                onPressed: _nextQuestion,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(
                  _currentIndex < widget.quiz.length - 1 ? 'Next Question' : 'Finish Quiz',
                  style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                ),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentQuestion = widget.quiz[_currentIndex];
    final progress =
        (_currentIndex + (_hasAnsweredCurrent ? 1 : 0)) / widget.quiz.length;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // FIX: Using PopScope with onPopInvokedWithResult to handle predictive back 
    // gestures and remove the WillPopScope deprecation warning.
    return PopScope(
      canPop: _canPop,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          setState(() {
            _canPop = true;
          });
          Future.microtask(() {
            if (context.mounted) Navigator.of(context).pop();
          });
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text(
            widget.deckTitle,
            style: TextStyle(
              fontWeight: FontWeight.bold, 
              fontSize: 18,
              color: Theme.of(context).appBarTheme.foregroundColor,
            ),
          ),
          backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: Icon(Icons.close, color: Theme.of(context).appBarTheme.foregroundColor),
            onPressed: () async {
              if (_canPop) {
                Navigator.of(context).pop();
                return;
              }
              final shouldPop = await _onWillPop();
              if (shouldPop && context.mounted) {
                setState(() {
                  _canPop = true;
                });
                Future.microtask(() {
                  if (context.mounted) Navigator.of(context).pop();
                });
              }
            },
          ),
        ),
        body: SafeArea(
          child: Stack(
            children: [
              // Main content
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildProgressBar(progress, isDark),
                  _buildStatsRow(isDark),

                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Center(
                            child: Text(
                              'Question ${_currentIndex + 1} of ${widget.quiz.length}',
                              style: TextStyle(
                                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Expanded(flex: 3, child: _buildQuestionCard(currentQuestion, isDark)),
                          const SizedBox(height: 20),
                          Expanded(flex: 5, child: _buildOptionsList(currentQuestion, isDark)),
                          SizedBox(height: 56, child: _buildNavigationButtons(isDark)),
                        ],
                      ),
                    ),
                  ),

                  // --- ADDED BANNER AD PLACEMENT ---
                  // Strict 50px boundary reserved at the bottom to ensure the UI
                  // does not jump around when the ad loads over slow networks.
                  if (!kIsWeb && !ProService().isPro)
                    SizedBox(
                      height: 50,
                      width: double.infinity,
                      child: (_isBannerAdLoaded && _bannerAd != null)
                          ? AdWidget(ad: _bannerAd!)
                          : const SizedBox.shrink(),
                    ),
                ],
              ),

              // Full Page Loading Overlay Layer
              if (_isFinishing)
                Positioned.fill(
                  child: ClipRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                      child: Container(
                        color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.85),
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
                              "Calculating Score...",
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: Theme.of(context).textTheme.bodyLarge?.color,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              "Wrapping up your quiz results.\nShowing an ad in the meantime ☕",
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
            ],
          ),
        ),
      ),
    );
  }
}