import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/deck_model.dart';
import '../screens/chat/ai_chat_screen.dart';
import 'animated_mascot.dart';

class FloatingTutorButton extends StatefulWidget {
  final Deck deck;

  const FloatingTutorButton({super.key, required this.deck});

  @override
  State<FloatingTutorButton> createState() => _FloatingTutorButtonState();
}

class _FloatingTutorButtonState extends State<FloatingTutorButton> {
  bool _showBubble = false;
  late String _greeting;
  Timer? _timer;

  // A list of cute greetings the mascot can randomly say
  final List<String> _greetings = [
    "Need a hint?",
    "Stuck? Ask me!",
    "I'm here to help!",
    "You got this! ✨",
    "Let's ace this!",
    "Confused? Tap me!",
  ];

  @override
  void initState() {
    super.initState();
    
    // Pick a random greeting
    _greeting = _greetings[Random().nextInt(_greetings.length)];
    
    // Wait 1.5 seconds after the screen loads to pop the bubble up
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _showBubble = true;
        });
      }
    });

    // Automatically hide the bubble after 8 seconds so it's not distracting
    _timer = Timer(const Duration(seconds: 8), () {
      if (mounted) {
        setState(() {
          _showBubble = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 30),
      // Wrapped the entire Row in the GestureDetector so the whole area is clickable
      child: GestureDetector(
        // This ensures taps on the transparent parts of the image still register!
        behavior: HitTestBehavior.translucent, 
        onTap: () {
          HapticFeedback.lightImpact();
          
          // Hide the bubble immediately if they tap the mascot or the bubble
          setState(() {
            _showBubble = false;
          });
          
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AIChatScreen(deck: widget.deck),
            ),
          ).then((_) {
            // 🛡️ BUG FIX: Forces the UI to refresh and fetch the synced energy state when returning!
            if (mounted) setState(() {});
          });
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [          
            // --- The Floating Mascot Button ---
            const SizedBox(
              width: 65, 
              height: 65,
              child: AnimatedMascot(
                state: MascotState.happy,
                size: 65, // Fixed to match the SizedBox bounds
              ),
            ),
            
            // --- The Animated Text Bubble ---
            AnimatedOpacity(
              opacity: _showBubble ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
              child: AnimatedSlide(
                offset: _showBubble ? Offset.zero : const Offset(0.2, 0),
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOutBack, // Gives it a nice little spring effect
                child: Container(
                  // Changed to left: 8 since the bubble is now on the right of the mascot
                  margin: const EdgeInsets.only(left: 8, bottom: 35), 
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      bottomLeft: Radius.circular(4), // Sharp corner pointing left to the mascot
                      topRight: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(
                      color: const Color(0xFF8B4EFF).withValues(alpha: 0.3),
                      width: 1.5,
                    )
                  ),
                  child: Text(
                    _greeting,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}