import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import '../../../models/card_model.dart';

class FlashcardStackView extends StatefulWidget {
  final List<Flashcard> cards;
  final int currentIndex;
  final PageController pageController;
  final Function(int) onPageChanged;
  final Function(bool) onFlip;
  final VoidCallback onCorrect;
  final VoidCallback onIncorrect;

  const FlashcardStackView({
    super.key,
    required this.cards,
    required this.currentIndex,
    required this.pageController,
    required this.onPageChanged,
    required this.onFlip,
    required this.onCorrect,
    required this.onIncorrect,
  });

  @override
  State<FlashcardStackView> createState() => _FlashcardStackViewState();
}

class _FlashcardStackViewState extends State<FlashcardStackView> {
  bool _isFront = true;

  void _flipCard() {
    setState(() {
      _isFront = !_isFront;
    });
    widget.onFlip(_isFront);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.cards.isEmpty) return const SizedBox.shrink();
    
    return PageView.builder(
      controller: widget.pageController,
      physics: const BouncingScrollPhysics(), 
      onPageChanged: (index) {
        setState(() {
          _isFront = true;
        });
        widget.onPageChanged(index);
      },
      itemCount: widget.cards.length,
      itemBuilder: (context, index) {
        final card = widget.cards[index];
        return GestureDetector(
          onTap: _flipCard,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (Widget child, Animation<double> animation) {
              final rotateAnim = Tween(begin: pi, end: 0.0).animate(animation);
              return AnimatedBuilder(
                animation: rotateAnim,
                child: child,
                builder: (context, widget) {
                  final isUnder = (ValueKey(_isFront) != widget?.key);
                  var tilt = ((animation.value - 0.5).abs() - 0.5) * 0.003;
                  tilt *= isUnder ? -1.0 : 1.0;
                  final value = isUnder ? min(rotateAnim.value, pi / 2) : rotateAnim.value;
                  return Transform(
                    transform: Matrix4.rotationY(value)..setEntry(3, 0, tilt),
                    alignment: Alignment.center,
                    child: widget,
                  );
                },
              );
            },
            child: _isFront
                ? _buildCardSide(context, card, true, key: const ValueKey(true))
                : _buildCardSide(context, card, false, key: const ValueKey(false)),
          ),
        );
      },
    );
  }

  Widget _buildCardSide(BuildContext context, Flashcard card, bool isFront, {required Key key}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 450, // Prevents card from stretching too wide on tablets/web
          maxHeight: 650, // Prevents card from becoming awkwardly tall
        ),
        child: Container(
          key: key,
          width: double.infinity,
          height: double.infinity, // Forces consistent size regardless of text length
          margin: const EdgeInsets.fromLTRB(20, 10, 20, 50),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.4 : 0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
            border: Border.all(
              color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
              width: 1,
            ),
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.center,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8B4EFF).withOpacity(isDark ? 0.2 : 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          isFront ? "QUESTION" : "ANSWER",
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFF8B4EFF),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      isFront ? card.question : card.answer,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                        height: 1.4,
                      ),
                    ),
                    const Spacer(),
                    
                    // Dynamic bottom layout based on which side is showing
                    isFront
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.touch_app_rounded, size: 16, color: Colors.grey.shade500),
                              const SizedBox(width: 8),
                              Text(
                                "Tap to flip",
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // --- Red Flag (Need Review) ---
                              GestureDetector(
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  widget.onIncorrect();
                                },
                                behavior: HitTestBehavior.opaque, // Ensures the tap is captured over the card's flip tap
                                child: Container(
                                  height: 64,
                                  width: 64,
                                  decoration: BoxDecoration(
                                    color: Colors.redAccent.withOpacity(isDark ? 0.15 : 0.1),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.redAccent.withOpacity(isDark ? 0.5 : 0.8), 
                                      width: 2,
                                    ),
                                  ),
                                  child: const Icon(Icons.flag_rounded, color: Colors.redAccent, size: 32),
                                ),
                              ),
                              const SizedBox(width: 40), // Spacing between the two action buttons
                              
                              // --- Green Check (Got It) ---
                              GestureDetector(
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  widget.onCorrect();
                                },
                                behavior: HitTestBehavior.opaque,
                                child: Container(
                                  height: 64,
                                  width: 64,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF00C853), // Solid Green
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF00C853).withOpacity(0.4),
                                        blurRadius: 12,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(Icons.check_rounded, color: Colors.white, size: 32),
                                ),
                              ),
                            ],
                          ),
                  ],
                ),
              ),
              
              if (card.lastScore != null)
                Positioned(
                  top: 20,
                  right: 20,
                  child: _buildLastScoreIndicator(context, card.lastScore),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLastScoreIndicator(BuildContext context, int? lastScore) {
    if (lastScore == null) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    Color color;
    IconData iconData;
    String tooltipMsg;

    // Use < 3 to map to the 'Need Review' red flag logic and >= 3 for 'Got It'
    if (lastScore < 3) {
      color = Colors.redAccent;
      iconData = Icons.flag_rounded;
      tooltipMsg = "Last time: Need Review";
    } else {
      color = const Color(0xFF00C853);
      iconData = Icons.check_rounded;
      tooltipMsg = "Last time: Got It";
    }

    return Tooltip(
      message: tooltipMsg,
      triggerMode: TooltipTriggerMode.longPress,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(isDark ? 0.15 : 0.1),
          shape: BoxShape.circle,
          border: Border.all(color: color.withOpacity(0.5), width: 1.5),
        ),
        child: Icon(iconData, size: 18, color: color),
      ),
    );
  }
}