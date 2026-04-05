import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;
import '../../../utils/math_markdown.dart';

class QuizOptionItem extends StatelessWidget {
  final String option;
  final String letter;
  final bool hasAnswered;
  final bool isSelected;
  final bool isCorrect;
  final VoidCallback onTap;

  const QuizOptionItem({
    super.key,
    required this.option,
    required this.letter,
    required this.hasAnswered,
    required this.isSelected,
    required this.isCorrect,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color buttonColor = Theme.of(context).cardColor;
    Color textColor =
        Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87;
    Color borderColor = Colors.transparent;
    IconData? feedbackIcon;
    Color iconColor = Colors.transparent;

    if (hasAnswered) {
      if (isCorrect) {
        buttonColor =
            isDark ? Colors.green.withValues(alpha: 0.2) : Colors.green.shade50;
        borderColor = isDark ? Colors.greenAccent : Colors.green.shade400;
        textColor = isDark ? Colors.greenAccent : Colors.green.shade800;
        feedbackIcon = Icons.check_circle_rounded;
        iconColor = isDark ? Colors.greenAccent : Colors.green.shade500;
      } else if (isSelected) {
        buttonColor =
            isDark ? Colors.red.withValues(alpha: 0.2) : Colors.red.shade50;
        borderColor = isDark ? Colors.redAccent : Colors.red.shade400;
        textColor = isDark ? Colors.redAccent : Colors.red.shade800;
        feedbackIcon = Icons.cancel_rounded;
        iconColor = isDark ? Colors.redAccent : Colors.red.shade500;
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            color: buttonColor,
            border: Border.all(
                color: borderColor == Colors.transparent
                    ? (isDark ? Colors.white12 : Colors.grey.shade200)
                    : borderColor,
                width: borderColor == Colors.transparent ? 1.5 : 2),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              if (hasAnswered && (isCorrect || isSelected))
                BoxShadow(
                    color: iconColor.withValues(alpha: 0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5))
              else
                BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 4)),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: hasAnswered && (isCorrect || isSelected)
                      ? iconColor.withValues(alpha: 0.2)
                      : (isDark ? Colors.white12 : Colors.grey.shade100),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    letter,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: hasAnswered && (isCorrect || isSelected)
                          ? iconColor
                          : (isDark ? Colors.white54 : Colors.black54),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: MarkdownBody(
                  data: option,
                  builders: {'math': MathBuilder()},
                  extensionSet: md.ExtensionSet(
                    md.ExtensionSet.gitHubFlavored.blockSyntaxes,
                    [
                      ...md.ExtensionSet.gitHubFlavored.inlineSyntaxes,
                      MathSyntax()
                    ],
                  ),
                  styleSheet: MarkdownStyleSheet(
                    p: TextStyle(
                        fontSize: 16,
                        color: textColor,
                        fontWeight: hasAnswered && (isCorrect || isSelected)
                            ? FontWeight.bold
                            : FontWeight.w600),
                    pPadding: EdgeInsets.zero,
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
  }
}
