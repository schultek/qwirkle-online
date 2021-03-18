import 'dart:math';

import 'package:flutter/material.dart';
// ignore: import_of_legacy_library_into_null_safe
import 'package:pimp_my_button/pimp_my_button.dart';

class Firework extends StatefulWidget {
  final Size size;
  final bool loop;
  final Offset? offset;
  const Firework(this.size, {this.loop = true, this.offset});

  @override
  _FireworkState createState() => _FireworkState();
}

class _FireworkState extends State<Firework> {
  late double x, y;
  Random random = Random();
  bool stop = false;

  @override
  void initState() {
    super.initState();

    stop = !widget.loop;

    if (widget.offset != null) {
      x = widget.offset!.dx;
      y = widget.offset!.dy;
    } else {
      updatePosition();
    }
  }

  void updatePosition() {
    x = random.nextInt(widget.size.width.toInt() - 100).toDouble();
    y = random.nextInt(widget.size.height.toInt() - 100).toDouble();
  }

  void play(AnimationController controller) {
    controller.forward(from: 0).then((_) async {
      if (!stop) {
        var d = random.nextInt(2000);
        Future.delayed(Duration(milliseconds: d), () {
          if (!stop) {
            updatePosition();
            setState(() {});
            play(controller);
          }
        });
      }
    });
  }

  @override
  void dispose() {
    stop = true;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: x,
      top: y,
      child: PimpedButton(
        particle: DemoParticle(),
        duration: const Duration(seconds: 1),
        pimpedWidgetBuilder: (context, controller) {
          play(controller);
          return const SizedBox(
            width: 100,
            height: 100,
          );
        },
      ),
    );
  }
}
