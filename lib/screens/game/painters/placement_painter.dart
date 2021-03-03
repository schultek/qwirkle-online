import 'package:flutter/material.dart';

import '../../../models/token.dart';
import 'token_painter_mixin.dart';

class PlacementPainter extends CustomPainter with TokenPainterMixin {
  final TokenPlacement? placement;

  PlacementPainter(this.placement);

  @override
  void paint(Canvas canvas, Size size) {
    if (placement != null) {
      paintToken(canvas, placement!.pos, placement!.token, opacity: 0.5);
    }
  }

  @override
  bool shouldRepaint(covariant PlacementPainter oldDelegate) => oldDelegate.placement != placement;
}
