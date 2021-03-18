// ignore: import_of_legacy_library_into_null_safe
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/game.dart';
import 'board.dart';
import 'firework.dart';
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
