import 'package:flutter/material.dart';
import 'quiz_creator.dart'; // Make sure to import your engine and models
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

  void _checkAnswer(String answer) {
    if (_hasAnswered) return; // Prevent tapping multiple times

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

  void _showResults() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Quiz Complete!"),
        content: Text(
          "You scored $_score out of ${widget.quiz.length}.",
          style: const TextStyle(fontSize: 18),
        ),
        actions: [
          TextButton(
            onPressed: () {
              // Pop the dialog, then pop the quiz screen to return to the deck
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text("Return to Deck"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentQuestion = widget.quiz[_currentIndex];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.deckTitle),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Progress Indicator
              Text(
                "Question ${_currentIndex + 1} of ${widget.quiz.length}",
                style: const TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              // The Question
              Expanded(
                flex: 2,
                child: Center(
                  child: Text(
                    currentQuestion.question,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // The Options
              Expanded(
                flex: 3,
                child: ListView.builder(
                  itemCount: currentQuestion.options.length,
                  itemBuilder: (context, index) {
                    final option = currentQuestion.options[index];

                    // Determine button colors based on state
                    Color buttonColor = Colors.white;
                    Color textColor = Colors.black87;
                    Color borderColor = Colors.grey.shade300;

                    if (_hasAnswered) {
                      if (option == currentQuestion.correctAnswer) {
                        buttonColor = Colors.green.shade100;
                        borderColor = Colors.green;
                        textColor = Colors.green.shade800;
                      } else if (option == _selectedAnswer) {
                        buttonColor = Colors.red.shade100;
                        borderColor = Colors.red;
                        textColor = Colors.red.shade800;
                      }
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: InkWell(
                        onTap: () => _checkAnswer(option),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: buttonColor,
                            border: Border.all(color: borderColor, width: 2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            option,
                            style: TextStyle(
                              fontSize: 16,
                              color: textColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Next Button (Only visible after answering)
              if (_hasAnswered)
                ElevatedButton(
                  onPressed: _nextQuestion,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: const Color(
                      0xFF2C1A8A,
                    ), // MindFlash purple
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _currentIndex < widget.quiz.length - 1
                        ? "Next Question"
                        : "Finish Quiz",
                    style: const TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
