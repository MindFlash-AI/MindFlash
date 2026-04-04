import 'package:flutter/material.dart';

// Robust Data Model for individual continuous strokes
class DrawingStroke {
  final List<Offset> points;
  final Color color;
  final double width;

  DrawingStroke({
    required this.points,
    this.color = Colors.redAccent,
    this.width = 4.0,
  });

  Map<String, dynamic> toJson() {
    return {
      'points': points.map((p) => {'dx': p.dx, 'dy': p.dy}).toList(),
      'color': color.value,
      'width': width,
    };
  }

  factory DrawingStroke.fromJson(Map<String, dynamic> json) {
    return DrawingStroke(
      points: (json['points'] as List)
          .map((p) => Offset((p['dx'] as num).toDouble(), (p['dy'] as num).toDouble()))
          .toList(),
      color: Color(json['color'] as int),
      width: (json['width'] as num).toDouble(),
    );
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
        ..color = stroke.color
        ..strokeWidth = stroke.width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      if (stroke.points.isEmpty) continue;

      if (stroke.points.length == 1) {
        canvas.drawOval(Rect.fromCircle(center: stroke.points.first, radius: stroke.width / 2), paint..style = PaintingStyle.fill);
        continue;
      }

      final path = Path();
      path.moveTo(stroke.points.first.dx, stroke.points.first.dy);

      for (int i = 1; i < stroke.points.length; i++) {
        // Use bezier curves for smooth rendering rather than sharp straight lines
        final p0 = stroke.points[i - 1];
        final p1 = stroke.points[i];
        
        // Midpoint calculation for quadratic bezier curve smoothing
        final midPoint = Offset((p0.dx + p1.dx) / 2, (p0.dy + p1.dy) / 2);
        
        if (i == 1) {
          path.lineTo(midPoint.dx, midPoint.dy);
        } else {
          path.quadraticBezierTo(p0.dx, p0.dy, midPoint.dx, midPoint.dy);
        }
      }
      
      // Draw line to the final point
      if (stroke.points.length > 1) {
         path.lineTo(stroke.points.last.dx, stroke.points.last.dy);
      }

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant DrawingPainter oldDelegate) {
    return true; // Continuously update while dragging
  }
}