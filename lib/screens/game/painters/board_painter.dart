import 'package:flutter/material.dart';

import '../../../models/board.dart';
import '../../../models/token.dart';
import 'token_painter_mixin.dart';

class BoardPainter extends CustomPainter with TokenPainterMixin {
  final Map<Pos, Cell> board;
  BoardPainter(this.board);

  @override
  void paint(Canvas canvas, Size size) {
    for (var entry in board.entries) {
      paintCell(canvas, entry.key, entry.value);
    }
  }

  void paintCell(Canvas canvas, Pos pos, Cell cell) {
    if (cell is TokenPlaceholder) {
      paintPlaceholder(canvas, pos);
    } else if (cell is Token) {
      paintToken(canvas, pos, cell);
    }
  }

  @override
  bool shouldRepaint(covariant BoardPainter oldDelegate) {
    return !board.equals(oldDelegate.board);
  }
}
