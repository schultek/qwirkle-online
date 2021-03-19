import 'package:flutter/material.dart';

import '../screens/game/painters/logo_painter.dart';

class TitleScreen extends StatelessWidget {
  final Widget child;
  const TitleScreen(this.child);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade900,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _qwirkleTitle(),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _qwirkleTitle() {
    return AspectRatio(
      aspectRatio: 2,
      child: CustomPaint(
        painter: LogoPainter(),
      ),
    );
  }

  static Widget asToken(Widget child, [Color? color]) {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        margin: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: color ?? Colors.black,
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.all(10),
        child: child,
      ),
    );
  }
}
