import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:markdown/markdown.dart' as md;
import '../../models/quiz_question_model.dart';

class _MathSyntax extends md.InlineSyntax {
  _MathSyntax() : super(r'\$\$(.*?)\$\$|\$(.*?)\$');

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    final isDisplay = match[1] != null;
    final math = match[1] ?? match[2];
    final el = md.Element.text('math', math ?? '');
    el.attributes['display'] = isDisplay.toString();
    parser.addNode(el);
    return true;
  }
}

class _MathBuilder extends MarkdownElementBuilder {
  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    final isDisplay = element.attributes['display'] == 'true';
    return Padding(
      padding: EdgeInsets.symmetric(vertical: isDisplay ? 8.0 : 0.0),
      child: Math.tex(
        element.textContent,
        textStyle: preferredStyle?.copyWith(fontSize: 16),
        mathStyle: isDisplay ? MathStyle.display : MathStyle.text,
        onErrorFallback: (err) => Text(element.textContent, style: preferredStyle?.copyWith(color: Colors.redAccent)),
      ),
    );
  }
}

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
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Theme.of(context).appBarTheme.foregroundColor),
          ),
          backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: Icon(Icons.close, color: Theme.of(context).appBarTheme.foregroundColor),
            onPressed: onClose,
          ),
        ),
        body: SafeArea(
          child: Center(
            // 🚀 HCI OPTIMIZATION: Constrains width on Web/Desktop so buttons aren't excessively wide
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 850),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildProgressBar(progress, isDark),
                  _buildStatsRow(isDark),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (child, animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(begin: const Offset(0.05, 0), end: Offset.zero).animate(animation),
                            child: child,
                          ),
                        );
                      },
                      child: Padding(
                        key: ValueKey<int>(currentIndex),
                        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05), 
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'Question ${currentIndex + 1} of ${quiz.length}', 
                                  style: TextStyle(
                                    color: isDark ? Colors.white70 : Colors.grey.shade700, 
                                    fontWeight: FontWeight.bold, 
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Expanded(flex: 4, child: _buildQuestionCard(context, currentQuestion, isDark)),
                            const SizedBox(height: 20),
                            Expanded(flex: 6, child: _buildOptionsList(context, currentQuestion, isDark)),
                            
                            if (hasAnsweredCurrent)
                              Padding(
                                padding: const EdgeInsets.only(top: 12.0),
                                child: Center(
                                  child: TextButton.icon(
                                    onPressed: () => onExplainRequested(currentQuestion, selectedAnswerCurrent),
                                    icon: const Icon(Icons.auto_awesome_rounded, color: Color(0xFF8B4EFF), size: 18),
                                    label: const Text("Ask AI Tutor to Explain", style: TextStyle(color: Color(0xFF8B4EFF), fontWeight: FontWeight.bold)),
                                    style: TextButton.styleFrom(backgroundColor: const Color(0xFF8B4EFF).withValues(alpha: 0.1), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
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
                    child: SizedBox(height: 56, child: _buildNavigationButtons(isDark)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
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
        decoration: BoxDecoration(color: isDark ? Colors.white12 : Colors.grey.shade200, borderRadius: BorderRadius.circular(3)),
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: value,
          child: Container(decoration: BoxDecoration(gradient: _brandGradient, borderRadius: BorderRadius.circular(3))),
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
          _buildStatBadge(Icons.check_circle_rounded, isDark ? Colors.greenAccent.shade400 : Colors.green.shade600, '$correctCount'),
          _buildStatBadge(Icons.cancel_rounded, isDark ? Colors.redAccent.shade200 : Colors.red.shade500, '$incorrectCount'),
          _buildStatBadge(Icons.help_outline_rounded, isDark ? Colors.white54 : Colors.grey.shade500, '$remainingCount'),
        ],
      ),
    );
  }

  Widget _buildStatBadge(IconData icon, Color color, String text) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 6),
        Text(text, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }

  Widget _buildQuestionCard(BuildContext context, QuizQuestion currentQuestion, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B142D) : Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: isDark ? const Color(0xFF8B4EFF).withValues(alpha: 0.3) : Colors.grey.shade200, width: 1.5),
        boxShadow: [BoxShadow(color: const Color(0xFF8B4EFF).withValues(alpha: isDark ? 0.15 : 0.05), blurRadius: 30, offset: const Offset(0, 10))],
      ),
      child: Center(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.help_outline_rounded, color: const Color(0xFF8B4EFF).withValues(alpha: 0.5), size: 40),
              const SizedBox(height: 16),
              MarkdownBody(
                data: currentQuestion.question,
                selectable: true,
                builders: {'math': _MathBuilder()},
                extensionSet: md.ExtensionSet(
                  md.ExtensionSet.gitHubFlavored.blockSyntaxes,
                  [...md.ExtensionSet.gitHubFlavored.inlineSyntaxes, _MathSyntax()],
                ),
                styleSheet: MarkdownStyleSheet(
                  p: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Theme.of(context).textTheme.bodyLarge?.color, height: 1.4, letterSpacing: -0.5),
                  pPadding: EdgeInsets.zero,
                  textAlign: WrapAlignment.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionsList(BuildContext context, QuizQuestion currentQuestion, bool isDark) {
    final letters = ['A', 'B', 'C', 'D', 'E', 'F'];
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      itemCount: currentQuestion.options.length,
      itemBuilder: (context, index) {
        final option = currentQuestion.options[index];
        final letter = letters[index % letters.length];
        Color buttonColor = Theme.of(context).cardColor;
        Color textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87;
        Color borderColor = Colors.transparent;
        IconData? feedbackIcon;
        Color iconColor = Colors.transparent;

        if (hasAnsweredCurrent) {
          if (option == currentQuestion.correctAnswer) {
            buttonColor = isDark ? Colors.green.withValues(alpha: 0.2) : Colors.green.shade50;
            borderColor = isDark ? Colors.greenAccent : Colors.green.shade400;
            textColor = isDark ? Colors.greenAccent : Colors.green.shade800;
            feedbackIcon = Icons.check_circle_rounded;
            iconColor = isDark ? Colors.greenAccent : Colors.green.shade500;
          } else if (option == selectedAnswerCurrent) {
            buttonColor = isDark ? Colors.red.withValues(alpha: 0.2) : Colors.red.shade50;
            borderColor = isDark ? Colors.redAccent : Colors.red.shade400;
            textColor = isDark ? Colors.redAccent : Colors.red.shade800;
            feedbackIcon = Icons.cancel_rounded;
            iconColor = isDark ? Colors.redAccent : Colors.red.shade500;
          }
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: InkWell(
            onTap: () => onCheckAnswer(option),
            borderRadius: BorderRadius.circular(20),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              decoration: BoxDecoration(
                color: buttonColor,
                border: Border.all(color: borderColor == Colors.transparent ? (isDark ? Colors.white12 : Colors.grey.shade200) : borderColor, width: borderColor == Colors.transparent ? 1.5 : 2),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  if (hasAnsweredCurrent && (option == currentQuestion.correctAnswer || option == selectedAnswerCurrent))
                    BoxShadow(color: iconColor.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 5))
                  else
                    BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02), blurRadius: 8, offset: const Offset(0, 4)),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: hasAnsweredCurrent && (option == currentQuestion.correctAnswer || option == selectedAnswerCurrent) ? iconColor.withValues(alpha: 0.2) : (isDark ? Colors.white12 : Colors.grey.shade100),
                      shape: BoxShape.circle,
                    ),
                    child: Center(child: Text(letter, style: TextStyle(fontWeight: FontWeight.bold, color: hasAnsweredCurrent && (option == currentQuestion.correctAnswer || option == selectedAnswerCurrent) ? iconColor : (isDark ? Colors.white54 : Colors.black54)))),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: MarkdownBody(
                      data: option,
                      builders: {'math': _MathBuilder()},
                      extensionSet: md.ExtensionSet(
                        md.ExtensionSet.gitHubFlavored.blockSyntaxes,
                        [...md.ExtensionSet.gitHubFlavored.inlineSyntaxes, _MathSyntax()],
                      ),
                      styleSheet: MarkdownStyleSheet(
                        p: TextStyle(fontSize: 16, color: textColor, fontWeight: hasAnsweredCurrent && (option == currentQuestion.correctAnswer || option == selectedAnswerCurrent) ? FontWeight.bold : FontWeight.w600),
                        pPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  if (feedbackIcon != null) Icon(feedbackIcon, color: iconColor, size: 24),
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
        if (currentIndex > 0)
          Expanded(
            flex: 1,
            child: OutlinedButton(
              onPressed: onPreviousQuestion,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                side: BorderSide(color: isDark ? Colors.white24 : Colors.grey.shade300, width: 2),
              ),
              child: Text('Previous', style: TextStyle(fontSize: 16, color: isDark ? Colors.white70 : Colors.grey.shade700, fontWeight: FontWeight.bold)),
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
                boxShadow: [BoxShadow(color: const Color(0xFF8B4EFF).withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 6))],
              ),
              child: ElevatedButton(
                onPressed: onNextQuestion,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                child: Text(currentIndex < quiz.length - 1 ? 'Next Question' : 'Finish Quiz', style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
              ),
            ),
          ),
      ],
    );
  }
}