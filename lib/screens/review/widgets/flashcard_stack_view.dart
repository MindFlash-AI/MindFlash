import 'dart:math';
import 'package:flutter/material.dart';
import '../../../models/card_model.dart';

class FlashcardStackView extends StatefulWidget {
  final List<Flashcard> cards;
  final int currentIndex;
  final PageController pageController;
  final Function(int) onPageChanged;
  final Function(bool)? onFlip;

  const FlashcardStackView({
    super.key,
    required this.cards,
    required this.currentIndex,
    required this.pageController,
    required this.onPageChanged,
    this.onFlip,
  });

  @override
  State<FlashcardStackView> createState() => _FlashcardStackViewState();
}

class _FlashcardStackViewState extends State<FlashcardStackView> {
  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: widget.pageController,
      onPageChanged: widget.onPageChanged,
      physics: const BouncingScrollPhysics(),
      itemCount: widget.cards.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: _FlipCard(
            card: widget.cards[index],
            cardNumber: index + 1,
            totalCards: widget.cards.length,
            onFlip: widget.onFlip,
          ),
        );
      },
    );
  }
}

class _FlipCard extends StatefulWidget {
  final Flashcard card;
  final int cardNumber;
  final int totalCards;
  final Function(bool)? onFlip;
  
  const _FlipCard({
    required this.card,
    required this.cardNumber,
    required this.totalCards,
    this.onFlip,
  });

  @override
  State<_FlipCard> createState() => _FlipCardState();
}

class _FlipCardState extends State<_FlipCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isFront = true;

  @override
  void initState() {
    super.initState();
    // 3D Flip Animation setup
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleCard() {
    if (_isFront) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
    _isFront = !_isFront;
    if (widget.onFlip != null) {
      widget.onFlip!(_isFront);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleCard,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          final angle = _animation.value * pi;
          final isUnder = angle > pi / 2;

          return Transform(
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001) // Adds 3D perspective depth
              ..rotateY(angle),
            alignment: Alignment.center,
            child: isUnder
                ? Transform(
                    transform: Matrix4.identity()..rotateY(pi),
                    alignment: Alignment.center,
                    child: _buildCardFace(isQuestion: false),
                  )
                : _buildCardFace(isQuestion: true),
          );
        },
      ),
    );
  }

  Widget _buildCardFace({required bool isQuestion}) {
    final text = isQuestion ? widget.card.question : widget.card.answer;
    final label = isQuestion ? "Q" : "A";
    
    // Day (Question) vs Night (Answer) Color Scheme
    final bgColor = isQuestion ? Colors.white : const Color(0xFF2A1B54);
    final primaryColor = isQuestion ? const Color(0xFF8B4EFF) : const Color(0xFFE841A1);
    final textColor = isQuestion ? Colors.black87 : Colors.white;
    final watermarkColor = isQuestion 
        ? primaryColor.withOpacity(0.04) 
        : Colors.white.withOpacity(0.05);

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(isQuestion ? 0.15 : 0.3),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(
          color: isQuestion ? primaryColor.withOpacity(0.2) : Colors.transparent,
          width: 2,
        ),
      ),
      child: Stack(
        children: [
          // Background Watermark Letter
          Positioned(
            right: -20,
            bottom: -20,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 180,
                fontWeight: FontWeight.bold,
                color: watermarkColor,
                height: 1,
              ),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Headers Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Card Progress Number (Number Only, More Prominent)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      decoration: BoxDecoration(
                        color: isQuestion 
                            ? primaryColor.withOpacity(0.15) 
                            : Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Text(
                        "${widget.cardNumber}",
                        style: TextStyle(
                          color: isQuestion ? primaryColor : Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    
                    // QUESTION / ANSWER Badge (More Prominent)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      decoration: BoxDecoration(
                        color: isQuestion 
                            ? primaryColor.withOpacity(0.15) 
                            : Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isQuestion ? Icons.help_outline_rounded : Icons.lightbulb_outline_rounded,
                            color: isQuestion ? primaryColor : Colors.white,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isQuestion ? "QUESTION" : "ANSWER",
                            style: TextStyle(
                              color: isQuestion ? primaryColor : Colors.white,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const Spacer(),
                
                // Main Formatted Content
                SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: _FormattedText(
                    text: text,
                    isQuestion: isQuestion,
                    textColor: textColor,
                    highlightColor: primaryColor,
                  ),
                ),
                
                const Spacer(),
                
                // Footer Instruction
                Text(
                  "Tap to flip",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isQuestion ? Colors.grey.shade400 : Colors.white54,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Custom Markdown Parser for the Card Content
class _FormattedText extends StatelessWidget {
  final String text;
  final bool isQuestion;
  final Color textColor;
  final Color highlightColor;

  const _FormattedText({
    required this.text, 
    required this.isQuestion,
    required this.textColor,
    required this.highlightColor,
  });

  List<TextSpan> _parseText(String content, TextStyle baseStyle) {
    final List<TextSpan> spans = [];
    
    // Regex to detect **bold** and *italic* generated by Gemini AI
    final RegExp exp = RegExp(r'(\*\*(.*?)\*\*)|(\*(.*?)\*)|([^_*]+)');
    final Iterable<RegExpMatch> matches = exp.allMatches(content);

    for (final match in matches) {
      if (match.group(1) != null) {
        // Render **bold**
        spans.add(TextSpan(
          text: match.group(2), 
          style: baseStyle.copyWith(
            fontWeight: FontWeight.w900,
            color: highlightColor, // Uses purple for Question, hot pink for Answer
          ),
        ));
      } else if (match.group(3) != null) {
        // Render *italic*
        spans.add(TextSpan(
          text: match.group(4), 
          style: baseStyle.copyWith(
            fontStyle: FontStyle.italic,
            fontWeight: isQuestion ? FontWeight.w600 : FontWeight.w400,
            color: isQuestion ? textColor.withOpacity(0.8) : Colors.white70,
          ),
        ));
      } else if (match.group(5) != null) {
        // Render normal text
        spans.add(TextSpan(text: match.group(5)));
      }
    }
    return spans;
  }

  @override
  Widget build(BuildContext context) {
    // QUESTION STYLE: Large, sleek sans-serif
    // ANSWER STYLE: Elegant Georgia serif, inherently italicized
    final baseStyle = isQuestion 
        ? TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w600,
            color: textColor,
            height: 1.4,
            letterSpacing: 0.2,
          )
        : TextStyle(
            fontSize: 22,
            fontFamily: 'Georgia', // Built-in iOS/Android serif font
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.w400, // Lighter weight for dark mode serif
            color: textColor,
            height: 1.6,
            letterSpacing: 0.3,
          );

    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: baseStyle,
        children: _parseText(text, baseStyle),
      ),
    );
  }
}