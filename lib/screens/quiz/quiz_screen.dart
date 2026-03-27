import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/quiz_question_model.dart';

class QuizScreen extends StatefulWidget {
  final List<QuizQuestion> quiz;
  final String deckTitle;

  const QuizScreen({super.key, required this.quiz, required this.deckTitle});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int _currentIndex = 0;
  late List<String?> _answers;

  // FIX: Debounce timer — instead of writing to SharedPreferences on every
  // answer and every navigation tap (up to 40 writes for a 20-question quiz),
  // we schedule a write 800 ms after the last state change. If the user taps
  // quickly through questions, intermediate states are skipped entirely.
  Timer? _saveDebounce;

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
  }

  @override
  void dispose() {
    // FIX: Flush any pending debounced save immediately on dispose so progress
    // is never lost when the user backgrounds the app mid-quiz.
    _saveDebounce?.cancel();
    _flushSave();
    super.dispose();
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

  // FIX: Schedules a debounced save. Only the final state within the 800 ms
  // window is persisted, collapsing many rapid taps into a single write.
  void _scheduleSave() {
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 800), _flushSave);
  }

  Future<void> _flushSave() async {
    final prefs = await SharedPreferences.getInstance();
    final savedAnswers = _answers.map((e) => e ?? '').toList();
    await prefs.setStringList('quiz_answers_${widget.deckTitle}', savedAnswers);
    await prefs.setInt('quiz_index_${widget.deckTitle}', _currentIndex);
  }

  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final savedAnswers =
        prefs.getStringList('quiz_answers_${widget.deckTitle}');
    final savedIndex = prefs.getInt('quiz_index_${widget.deckTitle}');

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
    await prefs.remove('quiz_answers_${widget.deckTitle}');
    await prefs.remove('quiz_index_${widget.deckTitle}');
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
    await _flushSave();

    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Pause Quiz?',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Your progress has been automatically saved. You can resume later.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B4EFF).withOpacity(0.1),
              foregroundColor: const Color(0xFF8B4EFF),
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
    await _clearProgress();
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'Quiz Complete!',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFFF9F5FF),
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
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
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

  @override
  Widget build(BuildContext context) {
    final currentQuestion = widget.quiz[_currentIndex];
    final progress =
        (_currentIndex + (_hasAnsweredCurrent ? 1 : 0)) / widget.quiz.length;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFFDF9FF),
        appBar: AppBar(
          title: Text(
            widget.deckTitle,
            style:
                const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          backgroundColor: const Color(0xFFFDF9FF),
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.black87),
            onPressed: () async {
              final shouldPop = await _onWillPop();
              if (shouldPop && context.mounted) Navigator.of(context).pop();
            },
          ),
        ),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: progress),
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) => Container(
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
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
              ),

              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatBadge(
                      Icons.check_circle_rounded,
                      Colors.green.shade600,
                      '$_correctCount',
                    ),
                    _buildStatBadge(
                      Icons.cancel_rounded,
                      Colors.red.shade500,
                      '$_incorrectCount',
                    ),
                    _buildStatBadge(
                      Icons.help_outline_rounded,
                      Colors.grey.shade500,
                      '$_remainingCount',
                    ),
                  ],
                ),
              ),

              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20.0, vertical: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Text(
                          'Question ${_currentIndex + 1} of ${widget.quiz.length}',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      Expanded(
                        flex: 3,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
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
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      Expanded(
                        flex: 5,
                        child: ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          itemCount: currentQuestion.options.length,
                          itemBuilder: (context, index) {
                            final option = currentQuestion.options[index];

                            Color buttonColor = Colors.white;
                            Color textColor = Colors.black87;
                            Color borderColor = Colors.transparent;
                            IconData? feedbackIcon;
                            Color iconColor = Colors.transparent;

                            if (_hasAnsweredCurrent) {
                              if (option == currentQuestion.correctAnswer) {
                                buttonColor = Colors.green.shade50;
                                borderColor = Colors.green.shade400;
                                textColor = Colors.green.shade800;
                                feedbackIcon = Icons.check_circle_rounded;
                                iconColor = Colors.green.shade500;
                              } else if (option == _selectedAnswerCurrent) {
                                buttonColor = Colors.red.shade50;
                                borderColor = Colors.red.shade400;
                                textColor = Colors.red.shade800;
                                feedbackIcon = Icons.cancel_rounded;
                                iconColor = Colors.red.shade500;
                              }
                            }

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: InkWell(
                                onTap: () => _checkAnswer(option),
                                borderRadius: BorderRadius.circular(16),
                                child: AnimatedContainer(
                                  duration:
                                      const Duration(milliseconds: 250),
                                  curve: Curves.easeInOut,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 16),
                                  decoration: BoxDecoration(
                                    color: buttonColor,
                                    border:
                                        Border.all(color: borderColor, width: 2),
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                            Colors.black.withOpacity(0.03),
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
                                        Icon(feedbackIcon,
                                            color: iconColor, size: 24),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      SizedBox(
                        height: 56,
                        child: Row(
                          children: [
                            if (_currentIndex > 0)
                              Expanded(
                                flex: 1,
                                child: OutlinedButton(
                                  onPressed: _previousQuestion,
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(16),
                                    ),
                                    side: BorderSide(
                                        color: Colors.grey.shade300, width: 2),
                                  ),
                                  child: Text(
                                    'Previous',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey.shade700,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),

                            if (_currentIndex > 0 && _hasAnsweredCurrent)
                              const SizedBox(width: 12),

                            if (_hasAnsweredCurrent)
                              Expanded(
                                flex: 2,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: _brandGradient,
                                    borderRadius:
                                        BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF8B4EFF)
                                            .withOpacity(0.3),
                                        blurRadius: 15,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton(
                                    onPressed: _nextQuestion,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(16),
                                      ),
                                    ),
                                    child: Text(
                                      _currentIndex < widget.quiz.length - 1
                                          ? 'Next Question'
                                          : 'Finish Quiz',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
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