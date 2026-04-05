import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../ai_chat_screen.dart';
import '../../../../widgets/animated_mascot.dart';

class ChatMessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isDark;
  final bool isDesktop;

  const ChatMessageBubble({
    super.key,
    required this.message,
    required this.isDark,
    this.isDesktop = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isDesktop ? 24.0 : 16.0),
      child: Row(
        mainAxisAlignment: message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!message.isUser) ...[
            Padding(
              padding: EdgeInsets.only(right: isDesktop ? 12.0 : 8.0), 
              child: const AnimatedMascot(state: MascotState.happy, size: 38),
            ),
          ],
          Flexible(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: isDesktop ? 24.0 : 18.0, vertical: isDesktop ? 16.0 : 14.0),
              decoration: BoxDecoration(
                color: message.isUser ? null : Theme.of(context).cardColor,
                gradient: message.isUser ? const LinearGradient(colors: [Color(0xFF8B4EFF), Color(0xFFE841A1)], begin: Alignment.topLeft, end: Alignment.bottomRight) : null,
                borderRadius: BorderRadius.only(topLeft: const Radius.circular(20), topRight: const Radius.circular(20), bottomLeft: Radius.circular(message.isUser ? 20 : 4), bottomRight: Radius.circular(message.isUser ? 4 : 20)),
                boxShadow: message.isUser ? null : [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.03), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: message.isUser
                  ? Text(message.text, style: const TextStyle(color: Colors.white, fontSize: 16, height: 1.4, fontWeight: FontWeight.w500))
                  : MarkdownBody(
                      data: message.text, 
                      selectable: true,
                      styleSheet: MarkdownStyleSheet(
                        p: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 16, height: 1.5), strong: TextStyle(fontWeight: FontWeight.w700, color: isDark ? Colors.white : Colors.black), em: TextStyle(fontStyle: FontStyle.italic, color: isDark ? Colors.white70 : Colors.black87), listBullet: const TextStyle(color: Color(0xFF8B4EFF), fontSize: 16), h1: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87), h2: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87), h3: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87), code: TextStyle(backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade100, color: const Color(0xFFE841A1), fontFamily: 'monospace', fontSize: 14), codeblockDecoration: BoxDecoration(color: isDark ? Colors.grey.shade800 : Colors.grey.shade100, borderRadius: BorderRadius.circular(8), border: Border.all(color: isDark ? Colors.grey.shade700 : Colors.grey.shade200)), blockquoteDecoration: BoxDecoration(border: const Border(left: BorderSide(color: Color(0xFF8B4EFF), width: 4)), color: const Color(0xFF8B4EFF).withValues(alpha: 0.05)), blockquotePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8)
                      ),
                    ),
            ),
          ),
          if (message.isUser) SizedBox(width: isDesktop ? 40 : 24),
        ],
      ),
    );
  }
}