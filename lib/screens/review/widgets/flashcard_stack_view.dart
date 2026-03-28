import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../models/card_model.dart';

class FlashcardStackView extends StatelessWidget {
  final List<Flashcard> cards;
  final int currentIndex;
  final PageController pageController;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<bool> onFlip;

  const FlashcardStackView({
    super.key,
    required this.cards,
    required this.currentIndex,
    required this.pageController,
    required this.onPageChanged,
    required this.onFlip,
  });

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: pageController,
      onPageChanged: onPageChanged,
      physics: const BouncingScrollPhysics(),
      itemCount: cards.length,
      itemBuilder: (context, index) {
        final card = cards[index];
        
        return LayoutBuilder(
          builder: (context, constraints) {
            double cardWidth = constraints.maxWidth * 0.85;
            double cardHeight = constraints.maxHeight * 0.82;

            const double optimalMaxWidth = 420.0;
            const double optimalMaxHeight = 560.0;

            if (cardWidth > optimalMaxWidth) cardWidth = optimalMaxWidth;
            if (cardHeight > optimalMaxHeight) cardHeight = optimalMaxHeight;

            return Center(
              child: SizedBox(
                width: cardWidth,
                height: cardHeight,
                child: _FlashcardWidget(
                  key: ValueKey('card_${card.id}_$index'),
                  card: card,
                  onFlip: onFlip,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _FlashcardWidget extends StatefulWidget {
  final Flashcard card;
  final ValueChanged<bool> onFlip;

  const _FlashcardWidget({
    super.key,
    required this.card,
    required this.onFlip,
  });

  @override
  State<_FlashcardWidget> createState() => _FlashcardWidgetState();
}

class _FlashcardWidgetState extends State<_FlashcardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isFront = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleCard() {
    HapticFeedback.lightImpact();
    if (_isFront) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
    setState(() {
      _isFront = !_isFront;
    });
    widget.onFlip(_isFront);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleCard,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          final angle = _animation.value * pi;
          
          final transform = Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(angle);

          final isBackVisible = angle >= pi / 2;

          return Transform(
            transform: transform,
            alignment: Alignment.center,
            child: isBackVisible
                ? Transform(
                    transform: Matrix4.identity()..rotateY(pi),
                    alignment: Alignment.center,
                    child: _buildCardFace(isFront: false),
                  )
                : _buildCardFace(isFront: true),
          );
        },
      ),
    );
  }

  Widget _buildCardFace({required bool isFront}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(32),
        border: isDark ? Border.all(color: Colors.white.withOpacity(0.05), width: 1) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.4 : 0.1),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: isFront
                  ? const Color(0xFF8B4EFF).withOpacity(isDark ? 0.15 : 0.1)
                  : const Color(0xFFE841A1).withOpacity(isDark ? 0.15 : 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isFront ? "QUESTION" : "ANSWER",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: isFront 
                    ? (isDark ? const Color(0xFFB48AFF) : const Color(0xFF8B4EFF)) 
                    : (isDark ? const Color(0xFFFF72C5) : const Color(0xFFE841A1)),
              ),
            ),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Text(
                  isFront ? widget.card.question : widget.card.answer,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isFront ? 24 : 20,
                    fontWeight: isFront ? FontWeight.bold : FontWeight.w600,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                    height: 1.4,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.touch_app_rounded,
                size: 16,
                color: isDark ? Colors.white38 : Colors.grey.shade400,
              ),
              const SizedBox(width: 8),
              Text(
                "Tap to flip",
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white38 : Colors.grey.shade400,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}