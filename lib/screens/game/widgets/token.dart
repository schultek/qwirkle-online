import 'package:flutter/material.dart';

import '../../../models/token.dart';

class QwirkleToken extends StatelessWidget {
  final Token token;
  QwirkleToken(this.token) : super(key: token.key);

  static const double size = 60;
  static const double gap = 2;
  static const double padding = 6;

  static Widget placeholder([Color? color, Color? bgColor]) {
    return buildWrapper(
      Container(),
      BoxDecoration(
        borderRadius: BorderRadius.circular(3),
        color: bgColor ?? Colors.grey.shade800.withOpacity(0.1),
        border: color != null ? Border.all(color: color) : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return buildWrapper(
      CustomPaint(painter: token.painter),
      BoxDecoration(
        borderRadius: BorderRadius.circular(3),
        color: Colors.black,
      ),
    );
  }

  static Widget buildWrapper(Widget child, BoxDecoration decoration) {
    return FittedBox(
      child: Container(
        padding: const EdgeInsets.all(gap),
        child: Container(
          decoration: decoration,
          width: size - gap * 2,
          height: size - gap * 2,
          padding: const EdgeInsets.all(padding),
          child: child,
        ),
      ),
    );
  }
}
