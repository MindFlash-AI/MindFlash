import 'package:flutter/material.dart';
import '../../models/quiz_question_model.dart';
import 'widgets/quiz_progress_bar.dart';
import 'widgets/quiz_stats_row.dart';
import 'widgets/quiz_question_card.dart';
import 'widgets/quiz_option_item.dart';

class QuizWeb extends StatelessWidget {
  final List<QuizQuestion> quiz;
  final String deckTitle;
  final int currentIndex;
  final List<String?> answers;
  final bool hasAnsweredCurrent;
  final String? selectedAnswerCurrent;
  final int correctCount;
  final int incorrectCount;
  final int remainingCount;
  final bool isFinishing;
  final String overlayTitle;
  final String overlaySubtitle;
  final bool canPop;
  final Function(String) onCheckAnswer;
  final VoidCallback onNextQuestion;
  final VoidCallback onPreviousQuestion;
  final void Function(bool, dynamic) onPopInvoked;
  final VoidCallback onClose;
  final Function(QuizQuestion, String?) onExplainRequested;

  const QuizWeb({
    super.key,
    required this.quiz,
    required this.deckTitle,
    required this.currentIndex,
    required this.answers,
    required this.hasAnsweredCurrent,
    required this.selectedAnswerCurrent,
    required this.correctCount,
    required this.incorrectCount,
    required this.remainingCount,
    required this.isFinishing,
    required this.overlayTitle,
    required this.overlaySubtitle,
    required this.canPop,
    required this.onCheckAnswer,
    required this.onNextQuestion,
    required this.onPreviousQuestion,
    required this.onPopInvoked,
    required this.onClose,
    required this.onExplainRequested,
  });

  final LinearGradient _brandGradient = const LinearGradient(
    colors: [Color(0xFF8B4EFF), Color(0xFFE841A1)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  @override
  Widget build(BuildContext context) {
    final currentQuestion = quiz[currentIndex];
    final progress = (currentIndex + (hasAnsweredCurrent ? 1 : 0)) / quiz.length;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: canPop,
      onPopInvokedWithResult: onPopInvoked,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text(
            deckTitle,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Theme.of(context).appBarTheme.foregroundColor),
          ),
          backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: Icon(Icons.close,
                color: Theme.of(context).appBarTheme.foregroundColor),
            onPressed: onClose,
          ),
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 850),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  QuizProgressBar(
                      progress: progress, brandGradient: _brandGradient),
                  QuizStatsRow(
                    correctCount: correctCount,
                    incorrectCount: incorrectCount,
                    remainingCount: remainingCount,
                  ),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (child, animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                                    begin: const Offset(0.05, 0),
                                    end: Offset.zero)
                                .animate(animation),
                            child: child,
                          ),
                        );
                      },
                      child: Padding(
                        key: ValueKey<int>(currentIndex),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20.0, vertical: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.white10
                                      : Colors.black.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'Question ${currentIndex + 1} of ${quiz.length}',
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white70
                                        : Colors.grey.shade700,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Expanded(
                                flex: 4,
                                child: QuizQuestionCard(
                                    question: currentQuestion.question)),
                            const SizedBox(height: 20),
                            Expanded(
                                flex: 6,
                                child: _buildOptionsList(
                                    context, currentQuestion, isDark)),
                            if (hasAnsweredCurrent)
                              Padding(
                                padding: const EdgeInsets.only(top: 12.0),
                                child: Center(
                                  child: TextButton.icon(
                                    onPressed: () => onExplainRequested(
                                        currentQuestion,
                                        selectedAnswerCurrent),
                                    icon: const Icon(Icons.auto_awesome_rounded,
                                        color: Color(0xFF8B4EFF), size: 18),
                                    label: const Text("Ask AI Tutor to Explain",
                                        style: TextStyle(
                                            color: Color(0xFF8B4EFF),
                                            fontWeight: FontWeight.bold)),
                                    style: TextButton.styleFrom(
                                        backgroundColor: const Color(0xFF8B4EFF)
                                            .withValues(alpha: 0.1),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 12)),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                    child: SizedBox(
                        height: 56, child: _buildNavigationButtons(isDark)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOptionsList(
      BuildContext context, QuizQuestion currentQuestion, bool isDark) {
    final letters = ['A', 'B', 'C', 'D', 'E', 'F'];
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      itemCount: currentQuestion.options.length,
      itemBuilder: (context, index) {
        final option = currentQuestion.options[index];
        final letter = letters[index % letters.length];

        return QuizOptionItem(
          option: option,
          letter: letter,
          hasAnswered: hasAnsweredCurrent,
          isSelected: option == selectedAnswerCurrent,
          isCorrect: option == currentQuestion.correctAnswer,
          onTap: () => onCheckAnswer(option),
        );
      },
    );
  }

  Widget _buildNavigationButtons(bool isDark) {
    return Row(
      children: [
        if (currentIndex > 0)
          Expanded(
            flex: 1,
            child: OutlinedButton(
              onPressed: onPreviousQuestion,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                side: BorderSide(
                    color: isDark ? Colors.white24 : Colors.grey.shade300,
                    width: 2),
              ),
              child: Text('Previous',
                  style: TextStyle(
                      fontSize: 16,
                      color: isDark ? Colors.white70 : Colors.grey.shade700,
                      fontWeight: FontWeight.bold)),
            ),
          ),
        if (currentIndex > 0 && hasAnsweredCurrent) const SizedBox(width: 12),
        if (hasAnsweredCurrent)
          Expanded(
            flex: 2,
            child: Container(
              decoration: BoxDecoration(
                gradient: _brandGradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                      color: const Color(0xFF8B4EFF).withValues(alpha: 0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 6))
                ],
              ),
              child: ElevatedButton(
                onPressed: onNextQuestion,
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16))),
                child: Text(
                    currentIndex < quiz.length - 1
                        ? 'Next Question'
                        : 'Finish Quiz',
                    style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5)),
              ),
            ),
          ),
      ],
    );
  }
}
