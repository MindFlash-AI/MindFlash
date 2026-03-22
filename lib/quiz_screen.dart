import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'quiz_question.dart';

class QuizScreen extends StatefulWidget {
  final List<QuizQuestion> quiz;
  final String deckTitle;

  const QuizScreen({super.key, required this.quiz, required this.deckTitle});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int _currentIndex = 0;
  int _score = 0;
  bool _hasAnswered = false;
  String? _selectedAnswer;

  final LinearGradient _brandGradient = const LinearGradient(
    colors: [Color(0xFF8B4EFF), Color(0xFFE841A1)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  void _checkAnswer(String answer) {
    if (_hasAnswered) return;

    HapticFeedback.lightImpact();

    setState(() {
      _hasAnswered = true;
      _selectedAnswer = answer;
      if (answer == widget.quiz[_currentIndex].correctAnswer) {
        _score++;
      }
    });
  }

  void _nextQuestion() {
    if (_currentIndex < widget.quiz.length - 1) {
      setState(() {
        _currentIndex++;
        _hasAnswered = false;
        _selectedAnswer = null;
      });
    } else {
      _showResults();
    }
  }

  Future<bool> _onWillPop() async {
    if (_currentIndex == 0 && !_hasAnswered) return true;

    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "Quit Quiz?",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          "You will lose your current progress. Are you sure?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade50,
              foregroundColor: Colors.red,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              "Quit",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
    return shouldPop ?? false;
  }

  void _showResults() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          "Quiz Complete!",
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
              "You scored $_score out of ${widget.quiz.length}.",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
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
                "Return to Deck",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentQuestion = widget.quiz[_currentIndex];
    final progress =
        (_currentIndex + (_hasAnswered ? 1 : 0)) / widget.quiz.length;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFFDF9FF),
        appBar: AppBar(
          title: Text(
            widget.deckTitle,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
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

              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Text(
                          "Question ${_currentIndex + 1} of ${widget.quiz.length}",
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

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
                      const SizedBox(height: 30),

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

                            if (_hasAnswered) {
                              if (option == currentQuestion.correctAnswer) {
                                buttonColor = Colors.green.shade50;
                                borderColor = Colors.green.shade400;
                                textColor = Colors.green.shade800;
                                feedbackIcon = Icons.check_circle_rounded;
                                iconColor = Colors.green.shade500;
                              } else if (option == _selectedAnswer) {
                                buttonColor = Colors.red.shade50;
                                borderColor = Colors.red.shade400;
                                textColor = Colors.red.shade800;
                                feedbackIcon = Icons.cancel_rounded;
                                iconColor = Colors.red.shade500;
                              }
                            }

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16.0),
                              child: InkWell(
                                onTap: () => _checkAnswer(option),
                                borderRadius: BorderRadius.circular(16),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 250),
                                  curve: Curves.easeInOut,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 18,
                                  ),
                                  decoration: BoxDecoration(
                                    color: buttonColor,
                                    border: Border.all(
                                      color: borderColor,
                                      width: 2,
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.03),
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
                                        Icon(
                                          feedbackIcon,
                                          color: iconColor,
                                          size: 24,
                                        ),
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
                        child: AnimatedOpacity(
                          opacity: _hasAnswered ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 200),
                          child: IgnorePointer(
                            ignoring: !_hasAnswered,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: _brandGradient,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF8B4EFF,
                                    ).withOpacity(0.3),
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
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: Text(
                                  _currentIndex < widget.quiz.length - 1
                                      ? "Next Question"
                                      : "Finish Quiz",
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
