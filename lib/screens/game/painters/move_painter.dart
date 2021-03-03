import 'package:flutter/material.dart';

import '../../../models/token.dart';
import 'token_painter_mixin.dart';

class MovePainter extends CustomPainter with TokenPainterMixin {
  final List<TokenPlacement> move;

  MovePainter(this.move);

  @override
  void paint(Canvas canvas, Size size) {
    for (var placement in move) {
      paintPlaceholder(canvas, placement.pos, border: true);
    }
  }

  @override
  bool shouldRepaint(covariant MovePainter oldDelegate) {
    return oldDelegate.move != move;
  }
}
