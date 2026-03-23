import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'deck_model.dart';
import 'card_model.dart';
import 'review_completion.dart';
import 'card_storage_service.dart';

class ReviewScreen extends StatefulWidget {
  final Deck deck;
  final List<Flashcard> cards;
  final bool isShuffleOn;

  const ReviewScreen({
    super.key,
    required this.deck,
    required this.cards,
    required this.isShuffleOn,
  });

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  final CardStorageService _cardStorageService = CardStorageService();
  late List<Flashcard> _reviewCards;
  int _currentIndex = 0;
  bool _showAnswer = false;
  int _correctCount = 0;

  final double _cardHeight = 420.0;

  @override
  void initState() {
    super.initState();
    _reviewCards = List.from(widget.cards);
    if (widget.isShuffleOn) {
      _reviewCards.shuffle();
    }
  }

  void _nextCard() {
    if (_currentIndex < _reviewCards.length - 1) {
      setState(() {
        _currentIndex++;
        _showAnswer = false;
      });
    } else {
      _finishReview();
    }
  }

  void _previousCard() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _showAnswer = false;
      });
    }
  }

  void _handleAnswer(bool wasCorrect) {
    if (wasCorrect) _correctCount++;
    
    // Update the flag and mastered status
    Flashcard currentCard = _reviewCards[_currentIndex];
    if (wasCorrect) {
      currentCard.isMastered = true;
      currentCard.isFlagged = false;
    } else {
      currentCard.isFlagged = true;
      currentCard.isMastered = false;
    }
    _cardStorageService.updateCard(currentCard);

    _nextCard();
  }

  void _finishReview() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ReviewCompletionScreen(
          deck: widget.deck,
          totalCards: _currentIndex + 1,
          allCards: widget.cards,
          correctCards: _correctCount,
        ),
      ),
    );
  }

  void _onSwipe(DragEndDetails details) {
    if (details.primaryVelocity! < -300) {
      HapticFeedback.lightImpact();
      _nextCard();
    } else if (details.primaryVelocity! > 300) {
      HapticFeedback.lightImpact();
      _previousCard();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_reviewCards.isEmpty) return const Scaffold();

    return Scaffold(
      backgroundColor: const Color(0xFFFDF9FF),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 8.0,
                vertical: 8.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Colors.black87,
                      size: 18,
                    ),
                    label: const Text(
                      "Exit",
                      style: TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    "${_currentIndex + 1} / ${_reviewCards.length}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.shuffle,
                      color: Colors.black87,
                      size: 20,
                    ),
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _reviewCards.shuffle();
                        _currentIndex = 0;
                        _showAnswer = false;
                        _correctCount = 0;
                      });
                    },
                  ),
                ],
              ),
            ),

            _buildProgressBar(),

            Expanded(
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: 16),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF8B4EFF), Color(0xFFE841A1)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          if (_currentIndex < _reviewCards.length - 2)
                            Transform.translate(
                              offset: const Offset(0, 24),
                              child: Transform.scale(
                                scale: 0.88,
                                child: _buildStaticCardContainer(
                                  Colors.white.withOpacity(0.4),
                                ),
                              ),
                            ),
                          if (_currentIndex < _reviewCards.length - 1)
                            Transform.translate(
                              offset: const Offset(0, 12),
                              child: Transform.scale(
                                scale: 0.94,
                                child: _buildStaticCardContainer(
                                  Colors.white.withOpacity(0.7),
                                ),
                              ),
                            ),

                          GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() => _showAnswer = !_showAnswer);
                            },
                            onHorizontalDragEnd: _onSwipe,
                            child: Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 40,
                                vertical: 40,
                              ),
                              width: double.infinity,
                              height: _cardHeight,
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 500),
                                transitionBuilder:
                                    (Widget child, Animation<double> animation) {
                                      final rotateAnim =
                                          Tween(begin: pi, end: 0.0).animate(
                                            CurvedAnimation(
                                              parent: animation,
                                              curve: Curves.easeOutCubic,
                                            ),
                                          );

                                      return AnimatedBuilder(
                                        animation: rotateAnim,
                                        child: child,
                                        builder: (context, widget) {
                                          final isFront =
                                              widget!.key ==
                                              const ValueKey("front");
                                          final rotation = isFront
                                              ? rotateAnim.value
                                              : -rotateAnim.value;

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
                                child: _showAnswer
                                    ? _buildBackSide()
                                    : _buildFrontSide(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(
                      height: 100,
                      child: Padding(
                        padding: const EdgeInsets.only(
                          bottom: 20.0,
                          left: 24,
                          right: 24,
                        ),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: _showAnswer
                              ? Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    Expanded(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.redAccent
                                                  .withOpacity(0.3),
                                              blurRadius: 12,
                                              offset: const Offset(0, 6),
                                            ),
                                          ],
                                        ),
                                        child: ElevatedButton(
                                          onPressed: () {
                                            HapticFeedback.lightImpact();
                                            _handleAnswer(false);
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.white,
                                            foregroundColor: Colors.redAccent,
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 18,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            elevation: 0,
                                          ),
                                          child: const Text(
                                            "Need Review",
                                            style: TextStyle(
                                              fontWeight: FontWeight.w800,
                                              fontSize: 15,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(
                                                0xFF7A40F2,
                                              ).withOpacity(0.3),
                                              blurRadius: 12,
                                              offset: const Offset(0, 6),
                                            ),
                                          ],
                                        ),
                                        child: ElevatedButton(
                                          onPressed: () {
                                            HapticFeedback.lightImpact();
                                            _handleAnswer(true);
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.white,
                                            foregroundColor: const Color(
                                              0xFF7A40F2,
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 18,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            elevation: 0,
                                          ),
                                          child: const Text(
                                            "Got It",
                                            style: TextStyle(
                                              fontWeight: FontWeight.w800,
                                              fontSize: 15,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : const Center(
                                  child: Text(
                                    "Tap card to reveal answer",
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStaticCardContainer(Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
      width: double.infinity,
      height: _cardHeight,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(24),
      ),
    );
  }

  Widget _buildProgressBar() {
    double progress = _reviewCards.isEmpty
        ? 0
        : (_currentIndex + 1) / _reviewCards.length;
    return Container(
      height: 6,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(3),
      ),
      alignment: Alignment.centerLeft,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        width: MediaQuery.of(context).size.width * progress,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(3),
          gradient: const LinearGradient(
            colors: [Color(0xFF5A6DFF), Color(0xFFE335A0)],
          ),
        ),
      ),
    );
  }

  Widget _buildFrontSide() {
    return _buildCardBase(
      key: const ValueKey("front"),
      tagLabel: "QUESTION",
      tagColor: const Color(0xFF5A6DFF),
      tagBgColor: const Color(0xFFF4F6FF),
      tagBorderColor: const Color(0xFFD6DFFF),
      content: _reviewCards[_currentIndex].question,
      hintText: "Tap to reveal answer",
    );
  }

  Widget _buildBackSide() {
    return _buildCardBase(
      key: const ValueKey("back"),
      tagLabel: "ANSWER",
      tagColor: const Color(0xFFC042E6),
      tagBgColor: const Color(0xFFFCF0FF),
      tagBorderColor: const Color(0xFFEBC1FF),
      content: _reviewCards[_currentIndex].answer,
      hintText: "Tap to flip back",
    );
  }

  Widget _buildCardBase({
    required Key key,
    required String tagLabel,
    required Color tagColor,
    required Color tagBgColor,
    required Color tagBorderColor,
    required String content,
    required String hintText,
  }) {
    final currentCard = _reviewCards[_currentIndex];

    return Container(
      key: key,
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
      padding: const EdgeInsets.all(32.0),
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
                      if (currentCard.isFlagged)
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.flag_rounded, color: Colors.redAccent, size: 20),
                        )
                      else if (currentCard.isMastered)
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
          const Spacer(),
          Text(
            content,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              height: 1.4,
            ),
          ),
          const Spacer(),
          Text(
            hintText,
            style: const TextStyle(
              color: Colors.black38,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}