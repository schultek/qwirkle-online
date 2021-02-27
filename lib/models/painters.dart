import 'dart:math' as math;

import 'package:flutter/material.dart';

abstract class SymbolPainter extends CustomPainter {
  Color color;
  SymbolPainter(this.color);

  Paint get fillPaint => Paint()
    ..style = PaintingStyle.fill
    ..color = color;

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;

  static CustomPainter fromTag(String tag) {
    var color = colorFromTag(tag[0]);
    var p = tag[1];
    switch (p) {
      case "1":
        return SquarePainter(color);
      case "2":
        return CirclePainter(color);
      case "3":
        return RhombusPainter(color);
      case "4":
        return FlowerPainter(color);
      case "5":
        return StarPainter(color);
      case "6":
        return SpikePainter(color);
      default:
        return CirclePainter(color);
    }
  }

  static Color colorFromTag(String c) {
    switch (c) {
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

class CirclePainter extends SymbolPainter {
  CirclePainter(Color color) : super(color);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), size.width / 2, fillPaint);
  }
}

class SquarePainter extends SymbolPainter {
  SquarePainter(Color color) : super(color);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), fillPaint);
  }
}

class RhombusPainter extends SymbolPainter {
  RhombusPainter(Color color) : super(color);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(math.pi * 0.25);
    canvas.drawRect(Rect.fromCircle(center: Offset.zero, radius: size.width / 2 / math.sqrt(2)), fillPaint);
  }
}

class FlowerPainter extends SymbolPainter {
  FlowerPainter(Color color) : super(color);

  @override
  void paint(Canvas canvas, Size size) {
    var r = size.width * 0.206;
    canvas.drawCircle(Offset(size.width / 2, r), r, fillPaint);
    canvas.drawCircle(Offset(r, size.height / 2), r, fillPaint);
    canvas.drawCircle(Offset(size.width / 2, size.height - r), r, fillPaint);
    canvas.drawCircle(Offset(size.width - r, size.height / 2), r, fillPaint);
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), r, fillPaint);
  }
}

class StarPainter extends SymbolPainter {
  StarPainter(Color color) : super(color);

  int n = 8;

  @override
  void paint(Canvas canvas, Size size) {
    var path = Path();
    path.moveTo(size.width / 2, 0);
    var cx = size.width / 2, cy = size.height / 2;
    var or = cx, ir = cx * 0.5;
    var da = 2 * math.pi / n;
    for (var i = 0; i < n; i++) {
      var a = i * da + da / 2;
      path.lineTo(cx + math.sin(a) * ir, cy - math.cos(a) * ir);
      a = (i + 1) * da;
      path.lineTo(cx + math.sin(a) * or, cy - math.cos(a) * or);
    }
    path.close();

    canvas.drawPath(path, fillPaint);
  }
}

class SpikePainter extends SymbolPainter {
  SpikePainter(Color color) : super(color);

  int n = 4;

  @override
  void paint(Canvas canvas, Size size) {
    var path = Path();
    path.moveTo(0, 0);
    var cx = size.width / 2, cy = size.height / 2;
    var or = cx * math.sqrt(2), ir = cx * 0.45;
    var da = 2 * math.pi / n;
    for (var i = 0; i < n; i++) {
      var a = i * da;
      path.lineTo(cx + math.sin(a) * ir, cy - math.cos(a) * ir);
      a = i * da + da / 2;
      path.lineTo(cx + math.sin(a) * or, cy - math.cos(a) * or);
    }
    path.close();

    canvas.drawPath(path, fillPaint);
  }
}
