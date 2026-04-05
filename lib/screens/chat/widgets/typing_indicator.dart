import 'package:flutter/material.dart';

class TypingIndicator extends StatefulWidget {
  final Color color;
  const TypingIndicator({super.key, required this.color});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final double delay = index * 0.15;
            double val = _controller.value - delay;
            if (val < 0) val += 1.0;
            final double dy = val < 0.4 ? -4.0 * (1 - ((val - 0.2) / 0.2).abs()) : 0.0;
            final double opacity = val < 0.4 ? 1.0 : 0.4;
            return Transform.translate(
              offset: Offset(0, dy),
              child: Opacity(opacity: opacity, child: child),
            );
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 2.5),
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
          ),
        );
      }),
    );
  }
}