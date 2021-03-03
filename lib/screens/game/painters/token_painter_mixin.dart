import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../models/token.dart';

class TokenPainterMixin {
  static const double grid = 60;
  static const double gap = 2;
  static const double padding = 6;

  static const double side = grid - gap * 2;

  void paintPlaceholder(Canvas canvas, Pos pos, {bool border = false, Color? borderColor}) {
    double x = pos.x * grid + gap, y = pos.y * grid + gap;
    double w = side, h = side;

    var paint = Paint();

    if (!border) {
      paint.color = Colors.grey.shade800.withOpacity(0.1);
      paint.style = PaintingStyle.fill;
    } else {
      paint.color = borderColor ?? Colors.green.withOpacity(0.5);
      paint.style = PaintingStyle.stroke;
      paint.strokeWidth = 1;
      x += 0.5;
      y += 0.5;
      w -= 1;
      h -= 1;
    }

    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, h), const Radius.circular(3)),
      paint,
    );
  }

  void paintToken(Canvas canvas, Pos pos, Token token, {double opacity = 1}) {
    double x = pos.x * grid + gap, y = pos.y * grid + gap;
    double w = side, h = side;

    var backPaint = Paint()
      ..color = Colors.black.withOpacity(opacity)
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, h), const Radius.circular(3)),
      backPaint,
    );

    var paint = Paint()
      ..style = PaintingStyle.fill
      ..color = getColorFromTag(token.color).withOpacity(opacity);

    x += padding;
    y += padding;
    w -= padding * 2;
    h -= padding * 2;

    var half = w / 2;

    if (token.symbol == "1") {
      // circle
      canvas.drawCircle(Offset(x + half, y + half), half, paint);
    } else if (token.symbol == "2") {
      // square
      canvas.drawRect(Rect.fromLTWH(x, y, w, h), paint);
    } else if (token.symbol == "3") {
      // rhombus
      canvas.translate(x + half, y + half);
      canvas.rotate(math.pi * 0.25);
      canvas.drawRect(Rect.fromCircle(center: Offset.zero, radius: half / math.sqrt(2)), paint);
      canvas.rotate(-math.pi * 0.25);
      canvas.translate(-x - half, -y - half);
    } else if (token.symbol == "4") {
      // flower
      var r = w * 0.206;
      canvas.drawCircle(Offset(x + half, y + r), r, paint);
      canvas.drawCircle(Offset(x + r, y + half), r, paint);
      canvas.drawCircle(Offset(x + half, y + h - r), r, paint);
      canvas.drawCircle(Offset(x + w - r, y + half), r, paint);
      canvas.drawCircle(Offset(x + half, y + half), r, paint);
    } else if (token.symbol == "5") {
      // star
      var path = Path();
      path.moveTo(x + half, y);
      var cx = x + half, cy = y + half;
      var or = half, ir = half * 0.5;
      var da = 2 * math.pi / 8;
      for (var i = 0; i < 8; i++) {
        var a = i * da + da / 2;
        path.lineTo(cx + math.sin(a) * ir, cy - math.cos(a) * ir);
        a = (i + 1) * da;
        path.lineTo(cx + math.sin(a) * or, cy - math.cos(a) * or);
      }
      path.close();

      canvas.drawPath(path, paint);
    } else if (token.symbol == "6") {
      var path = Path();
      path.moveTo(x, y);
      var cx = x + half, cy = y + half;
      var or = half * math.sqrt(2), ir = half * 0.45;
      var da = 2 * math.pi / 4;
      for (var i = 0; i < 4; i++) {
        var a = i * da;
        path.lineTo(cx + math.sin(a) * ir, cy - math.cos(a) * ir);
        a = i * da + da / 2;
        path.lineTo(cx + math.sin(a) * or, cy - math.cos(a) * or);
      }
      path.close();

      canvas.drawPath(path, paint);
    }
  }

  static Color getColorFromTag(String tag) {
    switch (tag) {
      case "y":
        return Colors.yellow;
      case "o":
        return Colors.orange;
      case "r":
        return Colors.red;
      case "p":
        return Colors.purple;
      case "b":
        return Colors.blue;
      case "g":
        return Colors.green;
      default:
        return Colors.white;
    }
  }
}
