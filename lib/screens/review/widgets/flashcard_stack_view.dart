import 'package:flutter/material.dart';
import 'dart:math';
import '../../../models/card_model.dart';

class FlashcardStackView extends StatelessWidget {
  final int currentIndex;
  final int totalCards;
  final Flashcard currentCard;
  final bool showAnswer;
  final double cardHeight;
  final VoidCallback onTap;
  final Function(DragEndDetails) onSwipe;

  const FlashcardStackView({
    super.key,
    required this.currentIndex,
    required this.totalCards,
    required this.currentCard,
    required this.showAnswer,
    required this.cardHeight,
    required this.onTap,
    required this.onSwipe,
  });

  Widget _buildStaticCardContainer(Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
      width: double.infinity,
      height: cardHeight,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(24),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        if (currentIndex < totalCards - 2)
          Transform.translate(
            offset: const Offset(0, 24),
            child: Transform.scale(
              scale: 0.88,
              child: _buildStaticCardContainer(Colors.white.withOpacity(0.4)),
            ),
          ),
        if (currentIndex < totalCards - 1)
          Transform.translate(
            offset: const Offset(0, 12),
            child: Transform.scale(
              scale: 0.94,
              child: _buildStaticCardContainer(Colors.white.withOpacity(0.7)),
            ),
          ),

        GestureDetector(
          onTap: onTap,
          onHorizontalDragEnd: onSwipe,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
            width: double.infinity,
            height: cardHeight,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              transitionBuilder: (Widget child, Animation<double> animation) {
                final rotateAnim = Tween(begin: pi, end: 0.0).animate(
                  CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
                );

                return AnimatedBuilder(
                  animation: rotateAnim,
                  child: child,
                  builder: (context, widget) {
                    final isFront = widget!.key == const ValueKey("front");
                    final rotation = isFront ? rotateAnim.value : -rotateAnim.value;

                    if (rotateAnim.value > pi / 2) {
                      return const SizedBox.shrink();
                    }

                    return Transform(
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.001)
                        ..rotateY(rotation),
                      alignment: Alignment.center,
                      child: widget,
                    );
                  },
                );
              },
              child: showAnswer
                  ? _FlashcardSide(
                      key: const ValueKey("back"),
                      tagLabel: "ANSWER",
                      tagColor: const Color(0xFFC042E6),
                      tagBgColor: const Color(0xFFFCF0FF),
                      tagBorderColor: const Color(0xFFEBC1FF),
                      content: currentCard.answer,
                      hintText: "Tap to flip back",
                      card: currentCard,
                    )
                  : _FlashcardSide(
                      key: const ValueKey("front"),
                      tagLabel: "QUESTION",
                      tagColor: const Color(0xFF5A6DFF),
                      tagBgColor: const Color(0xFFF4F6FF),
                      tagBorderColor: const Color(0xFFD6DFFF),
                      content: currentCard.question,
                      hintText: "Tap to flip",
                      card: currentCard,
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

// Extracted internal physical card rendering to adhere to DRY
class _FlashcardSide extends StatelessWidget {
  final String tagLabel;
  final Color tagColor;
  final Color tagBgColor;
  final Color tagBorderColor;
  final String content;
  final String hintText;
  final Flashcard card;

  const _FlashcardSide({
    super.key,
    required this.tagLabel,
    required this.tagColor,
    required this.tagBgColor,
    required this.tagBorderColor,
    required this.content,
    required this.hintText,
    required this.card,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: tagBgColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: tagBorderColor),
                  ),
                  child: Text(
                    tagLabel,
                    style: TextStyle(
                      color: tagColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (card.isFlagged)
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.flag_rounded, color: Colors.redAccent, size: 20),
                        )
                      else if (card.isMastered)
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check_rounded, color: Colors.green, size: 20),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Text(
                  content,
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
          const SizedBox(height: 16),
          Text(
            hintText,
            style: const TextStyle(
              color: Colors.black38,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}