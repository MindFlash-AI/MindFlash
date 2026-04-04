import 'package:flutter/material.dart';

// Robust Data Model for individual continuous strokes
class DrawingStroke {
  final List<Offset> points;
  final Color color;
  final double width;
  final bool isHighlighter;
  
  Path? _cachedPath;
  int _lastPointCount = 0;

  DrawingStroke({
    required this.points,
    this.color = Colors.redAccent,
    this.width = 4.0,
    this.isHighlighter = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'points': points.map((p) => {'dx': p.dx, 'dy': p.dy}).toList(),
      'color': color.value,
      'width': width,
      'isHighlighter': isHighlighter,
    };
  }

  factory DrawingStroke.fromJson(Map<String, dynamic> json) {
    return DrawingStroke(
      points: (json['points'] as List)
          .map((p) => Offset((p['dx'] as num).toDouble(), (p['dy'] as num).toDouble()))
          .toList(),
      color: Color(json['color'] as int),
      width: (json['width'] as num).toDouble(),
      isHighlighter: json['isHighlighter'] as bool? ?? false,
    );
  }

  // 🚀 PERFORMANCE FIX: Cache path to prevent expensive O(N) recalculations on every frame
  Path getPath() {
    if (_cachedPath != null && _lastPointCount == points.length) {
      return _cachedPath!;
    }
    
    final path = Path();
    if (points.isEmpty) return path;

    path.moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      final p0 = points[i - 1];
      final p1 = points[i];
      
      final midPoint = Offset((p0.dx + p1.dx) / 2, (p0.dy + p1.dy) / 2);
      
      if (i == 1) {
        path.lineTo(midPoint.dx, midPoint.dy);
      } else {
        path.quadraticBezierTo(p0.dx, p0.dy, midPoint.dx, midPoint.dy);
      }
    }
    if (points.length > 1) path.lineTo(points.last.dx, points.last.dy);
    
    _cachedPath = path;
    _lastPointCount = points.length;
    return path;
  }
}

// Highly optimized painter for rendering lines smoothly
class DrawingPainter extends CustomPainter {
  final List<DrawingStroke> strokes;

  DrawingPainter({required this.strokes});

  @override
  void paint(Canvas canvas, Size size) {
    for (var stroke in strokes) {
      final paint = Paint()
        ..color = stroke.isHighlighter ? stroke.color.withOpacity(0.4) : stroke.color
        ..strokeWidth = stroke.width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      if (stroke.points.isEmpty) continue;

      if (stroke.points.length == 1) {
        canvas.drawOval(Rect.fromCircle(center: stroke.points.first, radius: stroke.width / 2), paint..style = PaintingStyle.fill);
        continue;
      }

      canvas.drawPath(stroke.getPath(), paint);
    }
  }

  @override
  bool shouldRepaint(covariant DrawingPainter oldDelegate) {
    return true; // Continuously update while dragging
  }
}

// 🚀 PERFORMANCE: Isolated painter solely for the hover cursor to prevent redrawing the entire drawing boundary on mouse move
class HoverCursorPainter extends CustomPainter {
  final Offset? hoverPosition;
  final double width;
  final Color color;
  final bool isEraser;
  final bool isHighlighter;

  HoverCursorPainter({
    required this.hoverPosition,
    required this.width,
    required this.color,
    required this.isEraser,
    required this.isHighlighter,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (hoverPosition == null) return;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    double radius;
    if (isEraser) {
      radius = 25.0; // Fixed radius from logic
      paint.color = const Color(0xFFE841A1); // Brand Pink
      canvas.drawCircle(hoverPosition!, radius, Paint()..style = PaintingStyle.fill..color = const Color(0xFFE841A1).withOpacity(0.15));
    } else if (isHighlighter) {
      radius = (width * 2.5) / 2;
      paint.color = color.withOpacity(0.8);
    } else {
      radius = width / 2;
      paint.color = color.withOpacity(0.8);
    }

    canvas.drawCircle(hoverPosition!, radius, paint);
  }

  @override
  bool shouldRepaint(covariant HoverCursorPainter oldDelegate) {
    return oldDelegate.hoverPosition != hoverPosition || oldDelegate.width != width || oldDelegate.color != color || oldDelegate.isEraser != isEraser || oldDelegate.isHighlighter != isHighlighter;
  }
}