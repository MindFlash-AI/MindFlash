import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;
import '../../../utils/math_markdown.dart';

class QuizQuestionCard extends StatelessWidget {
  final String question;

  const QuizQuestionCard({
    super.key,
    required this.question,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B142D) : Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: isDark
              ? const Color(0xFF8B4EFF).withValues(alpha: 0.3)
              : Colors.grey.shade200,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B4EFF)
                .withValues(alpha: isDark ? 0.15 : 0.05),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Center(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.help_outline_rounded,
                color: const Color(0xFF8B4EFF).withValues(alpha: 0.5),
                size: 40,
              ),
              const SizedBox(height: 16),
              MarkdownBody(
                data: question,
                selectable: true,
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
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                    height: 1.4,
                    letterSpacing: -0.5,
                  ),
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
}
