import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:markdown/markdown.dart' as md;
import '../ai_chat_screen.dart';
import '../../../widgets/animated_mascot.dart';

class MathSyntax extends md.InlineSyntax {
  MathSyntax() : super(r'\$\$(.*?)\$\$|\$(.*?)\$');

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

class MathBuilder extends MarkdownElementBuilder {
  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    final isDisplay = element.attributes['display'] == 'true';
    return Padding(
      padding: EdgeInsets.symmetric(vertical: isDisplay ? 12.0 : 0.0),
      child: Math.tex(
        element.textContent,
        textStyle: preferredStyle?.copyWith(fontSize: 15),
        mathStyle: isDisplay ? MathStyle.display : MathStyle.text,
        onErrorFallback: (err) => Text(element.textContent, style: preferredStyle?.copyWith(color: Colors.redAccent)),
      ),
    );
  }
}

class PremiumChatMessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isDark;
  final bool isDesktop;

  const PremiumChatMessageBubble({
    super.key,
    required this.message,
    required this.isDark,
    this.isDesktop = false,
  });

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: message.text));
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white),
            SizedBox(width: 12),
            Text("Copied to clipboard!", style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        backgroundColor: const Color(0xFF8B4EFF),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isDesktop ? 24.0 : 20.0),
      child: Row(
        mainAxisAlignment: message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!message.isUser) ...[
            Padding(
              padding: EdgeInsets.only(right: isDesktop ? 16.0 : 12.0),
              child: const AnimatedMascot(state: MascotState.happy, size: 42),
            ),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: isDesktop ? 24.0 : 20.0, vertical: isDesktop ? 18.0 : 16.0),
                  decoration: BoxDecoration(
                    color: message.isUser 
                        ? null 
                        : (isDark ? const Color(0xFF1B142D) : Colors.white),
                    gradient: message.isUser 
                        ? const LinearGradient(colors: [Color(0xFF8B4EFF), Color(0xFFE841A1)], begin: Alignment.topLeft, end: Alignment.bottomRight) 
                        : null,
                    border: message.isUser 
                        ? null 
                        : Border.all(color: isDark ? const Color(0xFF8B4EFF).withValues(alpha: 0.3) : Colors.grey.shade200, width: 1.5),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(24),
                      topRight: const Radius.circular(24),
                      bottomLeft: Radius.circular(message.isUser ? 24 : 6),
                      bottomRight: Radius.circular(message.isUser ? 6 : 24),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: message.isUser 
                            ? const Color(0xFF8B4EFF).withValues(alpha: 0.2) 
                            : Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      )
                    ],
                  ),
                  child: message.isUser
                      ? Text(message.text, style: const TextStyle(color: Colors.white, fontSize: 16, height: 1.4, fontWeight: FontWeight.w500))
                      : MarkdownBody(
                          data: message.text,
                          selectable: true,
                          builders: {'math': MathBuilder()},
                          extensionSet: md.ExtensionSet(md.ExtensionSet.gitHubFlavored.blockSyntaxes, [...md.ExtensionSet.gitHubFlavored.inlineSyntaxes, MathSyntax()]),
                          styleSheet: MarkdownStyleSheet(
                            p: TextStyle(color: isDark ? Colors.white.withValues(alpha: 0.9) : Colors.black87, fontSize: 16, height: 1.6, letterSpacing: 0.2),
                            strong: TextStyle(fontWeight: FontWeight.w800, color: isDark ? Colors.white : Colors.black),
                            em: TextStyle(fontStyle: FontStyle.italic, color: isDark ? Colors.white70 : Colors.black87),
                            listBullet: const TextStyle(color: Color(0xFF8B4EFF), fontSize: 18, fontWeight: FontWeight.bold),
                            h1: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black87, height: 1.3),
                            h2: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: isDark ? Colors.white : Colors.black87, height: 1.3),
                            h3: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: isDark ? Colors.white : Colors.black87, height: 1.3),
                            code: TextStyle(backgroundColor: isDark ? Colors.black45 : Colors.grey.shade100, color: const Color(0xFFE841A1), fontFamily: 'monospace', fontSize: 14, fontWeight: FontWeight.w600),
                            codeblockDecoration: BoxDecoration(color: isDark ? const Color(0xFF0D0A14) : Colors.grey.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: isDark ? Colors.white24 : Colors.grey.shade200)),
                            codeblockPadding: const EdgeInsets.all(16),
                            blockquoteDecoration: BoxDecoration(border: const Border(left: BorderSide(color: Color(0xFF8B4EFF), width: 4)), color: isDark ? const Color(0xFF8B4EFF).withValues(alpha: 0.1) : const Color(0xFF8B4EFF).withValues(alpha: 0.05), borderRadius: const BorderRadius.only(topRight: Radius.circular(8), bottomRight: Radius.circular(8))),
                            blockquotePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            horizontalRuleDecoration: BoxDecoration(border: Border(top: BorderSide(width: 1.5, color: isDark ? Colors.white12 : Colors.grey.shade200))),
                          ),
                        ),
                ),
                if (!message.isUser) ...[
                  const SizedBox(height: 6),
                  Padding(padding: const EdgeInsets.only(left: 8.0), child: InkWell(onTap: () => _copyToClipboard(context), borderRadius: BorderRadius.circular(12), child: Padding(padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.copy_rounded, size: 14, color: isDark ? Colors.white54 : Colors.black54), const SizedBox(width: 6), Text("Copy", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? Colors.white54 : Colors.black54))])))),
                ],
              ],
            ),
          ),
          if (message.isUser) SizedBox(width: isDesktop ? 60 : 32),
        ],
      ),
    );
  }
}