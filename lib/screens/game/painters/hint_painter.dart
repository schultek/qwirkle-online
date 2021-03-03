import 'package:flutter/material.dart';

import '../../../models/token.dart';
import 'token_painter_mixin.dart';

class PlacementHint {
  Pos pos;
  bool isAllowed;
  PlacementHint(this.pos, this.isAllowed);
}

class HintPainter extends CustomPainter with TokenPainterMixin {
  final PlacementHint? hint;

  HintPainter(this.hint);

  @override
  void paint(Canvas canvas, Size size) {
    if (hint != null) {
      paintPlaceholder(canvas, hint!.pos, border: true, borderColor: hint!.isAllowed ? Colors.green : Colors.red);
    }
  }

  @override
  bool shouldRepaint(covariant HintPainter oldDelegate) => oldDelegate.hint != hint;
}
