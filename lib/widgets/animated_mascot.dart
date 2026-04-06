import 'package:flutter/material.dart';

enum MascotState { happy, thinking, sad }

class AnimatedMascot extends StatefulWidget {
  final MascotState state;
  final double size;

  const AnimatedMascot({
    super.key, 
    this.state = MascotState.happy, 
    this.size = 100,
  });

  @override
  State<AnimatedMascot> createState() => _AnimatedMascotState();
}

class _AnimatedMascotState extends State<AnimatedMascot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    // Creates a gentle 2-second floating animation loop
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    
    // REDUCED: Changed from -6/6 to -3/3 for a much subtler, tighter float
    _animation = Tween<double>(begin: -3, end: 3).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String imagePath;
    switch (widget.state) {
      case MascotState.happy:
        imagePath = 'assets/mascot/happy.png';
        break;
      case MascotState.thinking:
        imagePath = 'assets/mascot/thinking.png';
        break;
      case MascotState.sad:
        imagePath = 'assets/mascot/sad.png';
        break;
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _animation.value), 
          child: Image.asset(
            imagePath,
            width: widget.size,
            height: widget.size,
            fit: BoxFit.contain,
            gaplessPlayback: true, // 🛡️ OPTIMIZATION: Prevents flickering when the mascot changes state
            errorBuilder: (context, error, stackTrace) => Icon(
              widget.state == MascotState.sad ? Icons.battery_alert : Icons.smart_toy_rounded,
              size: widget.size * 0.8,
              color: const Color(0xFF8B4EFF),
            ),
          ),
        );
      },
    );
  }
}