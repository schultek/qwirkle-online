import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:pimp_my_button/pimp_my_button.dart';
import 'package:provider/provider.dart';

import '../../../models/game.dart';
import 'board.dart';
import 'score_board.dart';

class FinishedArea extends StatefulWidget {
  @override
  _FinishedAreaState createState() => _FinishedAreaState();
}

class _FinishedAreaState extends State<FinishedArea> {
  AudioPlayer audioPlayer = AudioPlayer();
  static const String soundEffectUrl =
      "https://cdn.videvo.net/videvo_files/audio/premium/audio0090/watermarked/Fireworks%206083_95_preview.mp3";

  @override
  void initState() {
    super.initState();
    audioPlayer.play(soundEffectUrl, volume: 0.5);
    audioPlayer.onPlayerCompletion.listen((event) {
      audioPlayer.play(soundEffectUrl, volume: 0.5);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(child: QwirkleBoard(QwirkleBoard.globalKey)),
        Positioned.fill(
            child: Container(
          color: Colors.black38,
        )),
        ...List.generate(10, (i) => Firework(MediaQuery.of(context).size)),
        buildWinnerOverlay(),
        const ScoreBoard(),
      ],
    );
  }

  Widget buildWinnerOverlay() {
    var game = Provider.of<Game>(context, listen: false);

    if (game.players[game.winningPlayerId] != null) {
      return Center(
        child: Text(
          "Winner is ${game.players[game.winningPlayerId]!.nickname}",
          style: const TextStyle(fontSize: 60, color: Colors.white),
        ),
      );
    } else {
      return Container();
    }
  }
}

class Firework extends StatefulWidget {
  final Size size;
  const Firework(this.size);

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
    updatePosition();
  }

  void updatePosition() {
    x = random.nextInt(widget.size.width.toInt()).toDouble();
    y = random.nextInt(widget.size.height.toInt()).toDouble();
  }

  void play(AnimationController controller) {
    var d = random.nextInt(2000);

    Future.delayed(Duration(milliseconds: d), () {
      if (!stop) {
        controller.forward(from: 0).then((_) async {
          updatePosition();
          setState(() {});
          play(controller);
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
        duration: Duration(seconds: 1),
        pimpedWidgetBuilder: (context, controller) {
          play(controller);
          return Container(
            width: 100,
            height: 100,
          );
        },
      ),
    );
  }
}
