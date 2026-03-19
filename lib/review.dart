import 'package:flutter/material.dart';
import 'deck_model.dart';
import 'card_model.dart';
import 'review_completion.dart';

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
  late List<Flashcard> _reviewCards;
  int _currentIndex = 0;
  bool _showAnswer = false;

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

  void _finishReview() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ReviewCompletionScreen(
          deck: widget.deck,
          // If they finish early, we pass the current progress
          totalCards: _currentIndex + 1,
          allCards: widget.cards,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_reviewCards.isEmpty) return const Scaffold();

    return Scaffold(
      backgroundColor: const Color(0xFFFDF9FF), // Matches the top section color
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
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
                      setState(() {
                        _reviewCards.shuffle();
                        _currentIndex = 0;
                        _showAnswer = false;
                      });
                    },
                  ),
                ],
              ),
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
                        // Card Area
                        GestureDetector(
                          onTap: () =>
                              setState(() => _showAnswer = !_showAnswer),
                          child: Container(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 45,
                              vertical: 40,
                            ),
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 15,
                                  offset: Offset(0, 8),
                                ),
                              ],
                            ),
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              transitionBuilder: (child, animation) =>
                                  FadeTransition(
                                    opacity: animation,
                                    child: child,
                                  ),
                              child: _showAnswer
                                  ? _buildBackSide()
                                  : _buildFrontSide(),
                            ),
                          ),
                        ),

                        // Navigation Arrows
                        Positioned(
                          left: 10,
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back_ios, size: 36),
                            color: _currentIndex > 0
                                ? Colors.black87
                                : Colors.black26,
                            onPressed: _currentIndex > 0 ? _previousCard : null,
                          ),
                        ),
                        Positioned(
                          right: 10,
                          child: IconButton(
                            icon: const Icon(Icons.arrow_forward_ios, size: 36),
                            color: _currentIndex < _reviewCards.length - 1
                                ? Colors.black87
                                : Colors.black26,
                            onPressed: _currentIndex < _reviewCards.length - 1
                                ? _nextCard
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Bottom Area
                  SizedBox(
                    height: 80,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 40.0),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: _showAnswer
                            ? ElevatedButton(
                                onPressed: _finishReview,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: const Color(0xFF7A40F2),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 40,
                                    vertical: 10,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Text(
                                      "Finish Review",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Icon(Icons.check),
                                  ],
                                ),
                              )
                            : const Text(
                                "Tap card to reveal answer",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
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
      child: FractionallySizedBox(
        widthFactor: progress,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(3),
            gradient: const LinearGradient(
              colors: [Color(0xFF5A6DFF), Color(0xFFE335A0)],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFrontSide() {
    return Padding(
      key: const ValueKey("front"),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F6FF),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFD6DFFF)),
            ),
            child: const Text(
              "QUESTION",
              style: TextStyle(
                color: Color(0xFF5A6DFF),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Spacer(),
          Text(
            _reviewCards[_currentIndex].question,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              height: 1.4,
            ),
          ),
          const Spacer(),
          const Text(
            "Tap to reveal answer",
            style: TextStyle(color: Colors.black38, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildBackSide() {
    return Padding(
      key: const ValueKey("back"),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFCF0FF),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFEBC1FF)),
            ),
            child: const Text(
              "ANSWER",
              style: TextStyle(
                color: Color(0xFFC042E6),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Spacer(),
          Text(
            _reviewCards[_currentIndex].answer,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              height: 1.4,
            ),
          ),
          const Spacer(),
          const Text(
            "Tap to flip back",
            style: TextStyle(color: Colors.black38, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
