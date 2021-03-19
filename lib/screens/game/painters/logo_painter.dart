import 'package:flutter/material.dart';

import '../../../models/token.dart';

class LogoPainter extends CustomPainter {
  double grid = 120;
  double gap = 4;
  double padding = 12;

  double get side => grid - gap * 2;

  LogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    grid = size.width / 4;
    gap = grid / 30;
    padding = gap * 3;

    paintLetter(canvas, const Pos(0, 0), "q", Colors.blue);
    paintLetter(canvas, const Pos(1, 0), "w", Colors.red);
    paintLetter(canvas, const Pos(2, 0), "i", Colors.green);
    paintLetter(canvas, const Pos(3, 0), "r", Colors.orange);
    paintLetter(canvas, const Pos(0, 1), "k", Colors.purple);
    paintLetter(canvas, const Pos(1, 1), "l", Colors.yellow);
    paintPlaceholder(canvas, const Pos(3, 1));
    paintLetter(canvas, const Pos(2, 1), "e", Colors.blue);
  }

  void paintLetter(Canvas canvas, Pos pos, String letter, Color color) {
    double x = pos.x * grid + gap, y = pos.y * grid + gap;
    double w = side, h = side;

    var backPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, h), Radius.circular(gap * 2)),
      backPaint,
    );

    var letterPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    x += padding * 2;
    y += padding * 2;
    w -= padding * 4;
    h -= padding * 4;

    var path = Path();

    if (letter == "q") {
      path.moveTo(x + w, y + h);
      path.lineTo(x + w / 2, y + h);
      path.arcToPoint(Offset(x, y + h / 2), radius: Radius.circular(w / 2));
      path.arcToPoint(Offset(x + w / 2, y), radius: Radius.circular(w / 2));
      path.arcToPoint(Offset(x + w, y + h / 2), radius: Radius.circular(w / 2));
      path.close();
    } else if (letter == "w") {
      path.moveTo(x, y);
      path.lineTo(x + w * 0.25, y + h);
      path.lineTo(x + w / 2, y + h * 0.6);
      path.lineTo(x + w * 0.75, y + h);
      path.lineTo(x + w, y);
      path.close();
    } else if (letter == "i") {
      path.moveTo(x + w * 0.4, y);
      path.lineTo(x + w * 0.6, y);
      path.lineTo(x + w * 0.6, y + h);
      path.lineTo(x + w * 0.4, y + h);
      path.close();
    } else if (letter == "r") {
      path.moveTo(x + w * 0.15, y);
      path.lineTo(x + w * 0.5, y);
      path.arcToPoint(Offset(x + w * 0.6, y + h * 0.55), radius: Radius.circular(w / 4));
      path.lineTo(x + w * 0.85, y + h);
      path.lineTo(x + w * 0.15, y + h);
      path.close();
    } else if (letter == "k") {
      path.moveTo(x + w * 0.15, y);
      path.lineTo(x + w * 0.85, y);
      path.lineTo(x + w * 0.5, y + h * 0.5);
      path.lineTo(x + w * 0.85, y + h);
      path.lineTo(x + w * 0.15, y + h);
      path.close();
    } else if (letter == "l") {
      path.moveTo(x + w * 0.15, y);
      path.lineTo(x + w * 0.4, y);
      path.lineTo(x + w * 0.4, y + h * 0.8);
      path.lineTo(x + w * 0.85, y + h * 0.8);
      path.lineTo(x + w * 0.85, y + h);
      path.lineTo(x + w * 0.15, y + h);
      path.close();
    } else if (letter == "e") {
      path.moveTo(x + w * 0.15, y);
      path.lineTo(x + w * 0.85, y);
      path.lineTo(x + w * 0.85, y + h * 0.3);
      path.lineTo(x + w * 0.55, y + h * 0.3);
      path.lineTo(x + w * 0.55, y + h * 0.7);
      path.lineTo(x + w * 0.85, y + h * 0.7);
      path.lineTo(x + w * 0.85, y + h);
      path.lineTo(x + w * 0.15, y + h);
      path.close();
    }

    canvas.drawPath(path, letterPaint);
    letterPaint.style = PaintingStyle.stroke;
    letterPaint.strokeWidth = gap;
    letterPaint.strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, letterPaint);
  }

  void paintPlaceholder(Canvas canvas, Pos pos) {
    double x = pos.x * grid + gap, y = pos.y * grid + gap;
    double w = side, h = side;

    var paint = Paint();
    paint.color = Colors.grey.shade800.withOpacity(0.1);
    paint.style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, h), Radius.circular(gap * 2)),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant LogoPainter oldDelegate) => false;
}
