import 'package:flutter/material.dart';

import '../../../models/token.dart';
import 'token_painter_mixin.dart';

class CellPainter extends CustomPainter with TokenPainterMixin {
  final Cell cell;
  CellPainter(this.cell);

  @override
  void paint(Canvas canvas, Size size) {
    if (cell is TokenPlaceholder) {
      paintPlaceholder(canvas, const Pos(0, 0));
    } else if (cell is Token) {
      paintToken(canvas, const Pos(0, 0), cell as Token);
    }
  }

  @override
  bool shouldRepaint(covariant CellPainter oldDelegate) => oldDelegate.cell != cell;
}
