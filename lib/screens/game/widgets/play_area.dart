import 'dart:async';
import 'dart:ui';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// ignore: import_of_legacy_library_into_null_safe
import 'package:tuple/tuple.dart';

import '../../../models/game.dart';
import '../../../models/game_action.dart';
import 'board.dart';
import 'firework.dart';
import 'score_board.dart';
import 'token_selector.dart';

class PlayArea extends StatefulWidget {
  @override
  _PlayAreaState createState() => _PlayAreaState();
}

class _PlayAreaState extends State<PlayArea> {
  bool showReplaceAllButton = false;
  AudioPlayer audioPlayer = AudioPlayer();
  static const String soundEffectUrl = "https://assets.mixkit.co/sfx/preview/mixkit-casino-bling-achievement-2067.mp3";

  late StreamSubscription<Tuple2<String, String>> cmdSubscription;
  late StreamSubscription<Tuple2<String, String>> msgSubscription;

  @override
  void initState() {
    audioPlayer.setUrl(soundEffectUrl);
    cmdSubscription = Provider.of<Game>(context, listen: false)
        .messages
        .where((event) => event.item2.startsWith(":"))
        .listen((event) {
      if (event.item2.startsWith(":qwirkle")) {
        var entry = OverlayEntry(
          builder: (ctx) => Firework(
            MediaQuery.of(context).size,
            loop: false,
            offset: Offset(
              MediaQuery.of(context).size.width / 2 - 50,
              MediaQuery.of(context).size.height / 2 - 50,
            ),
          ),
        );
        Overlay.of(context)!.insert(entry);
        audioPlayer.play(soundEffectUrl, volume: 0.5);
        Future.delayed(const Duration(seconds: 1), () {
          entry.remove();
        });
      }
    });

    msgSubscription = Provider.of<Game>(context, listen: false)
        .messages
        .where((event) => !event.item2.startsWith(":"))
        .listen((event) {
      var entry = OverlayEntry(
        builder: (ctx) => Positioned(
          top: 70,
          left: 0,
          right: 0,
          child: Center(
            child: TweenAnimationBuilder<double>(
              duration: const Duration(seconds: 4),
              tween: Tween(begin: 0, end: 1),
              builder: (context, a, _) {
                return Opacity(
                  opacity: a <= 0.1
                      ? a * 5
                      : a >= 0.9
                          ? 1 - (a - 0.9) * 10
                          : 1,
                  child: Text(
                    event.item2,
                    style: const TextStyle(
                      color: Colors.green,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.none,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );
      Overlay.of(context)!.insert(entry);
      Future.delayed(const Duration(seconds: 4), () {
        entry.remove();
      });
    });

    super.initState();
  }

  @override
  void dispose() {
    cmdSubscription.cancel();
    msgSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(child: QwirkleBoard(QwirkleBoard.globalKey)),
        const Positioned(
          right: 0,
          top: 0,
          bottom: 0,
          child: TokenSelector(),
        ),
        Selector<Game, int?>(
          builder: (context, tokensLeft, _) => tokensLeft != null
              ? Positioned(
                  top: 20,
                  right: 20,
                  child: Text(
                    "$tokensLeft",
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                )
              : Container(),
          selector: (context, game) => game.mode == "normal" ? game.availableTokens.length : null,
        ),
        const ScoreBoard(),
        Positioned(
          left: 0,
          right: 0,
          top: 20,
          child: Center(child: buildPlayerHint()),
        ),
        AnimatedPositioned(
          left: 0,
          right: 0,
          bottom: showReplaceAllButton ? 110 : 50,
          duration: const Duration(milliseconds: 300),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: showReplaceAllButton ? 1 : 0,
            child: Center(
              child: actionButton(
                onPressed: () {
                  var game = Provider.of<Game>(context, listen: false);
                  game.requestAction(GameAction.replaceTokens(game.playerId), sendDuplicate: true);
                },
                text: "Ersetze alle Steine",
                color: Colors.orange,
              ),
            ),
          ),
        ),
        Selector<Game, bool>(
          selector: (context, game) => game.currentPlayerId == game.playerId,
          builder: (context, isCurrentPlayer, _) {
            if (isCurrentPlayer) {
              return Positioned(
                left: 0,
                right: 0,
                bottom: 50,
                child: Center(child: buildPlayerActions()),
              );
            } else {
              return Container();
            }
          },
        ),
      ],
    );
  }

  Widget buildPlayerHint() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(40),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(40),
            border: Border.all(color: Colors.green),
            color: Colors.black12,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Selector<Game, String>(
            selector: (context, game) =>
                game.currentPlayerId == game.playerId ? "Du bist" : "${game.currentPlayer!.nickname} ist",
            builder: (context, playerText, _) => Text(
              "$playerText am Zug",
              style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildPlayerActions() {
    return Selector<Game, bool>(
        selector: (context, game) => game.currentMove.isNotEmpty,
        builder: (context, hasPlayedTokens, _) {
          if (hasPlayedTokens) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                actionButton(
                  onPressed: () {
                    var game = Provider.of<Game>(context, listen: false);
                    game.requestAction(GameAction.back(game.playerId), sendDuplicate: true);
                  },
                  color: Colors.grey,
                  text: "Zurück",
                ),
                const SizedBox(width: 20),
                actionButton(
                  onPressed: () {
                    var game = Provider.of<Game>(context, listen: false);
                    game.requestAction(GameAction.finish(game.playerId));
                  },
                  color: Colors.green,
                  text: "Fertig",
                ),
              ],
            );
          } else {
            return actionButton(
              onPressed: () {
                setState(() => showReplaceAllButton = true);
                Future.delayed(const Duration(seconds: 2), () => setState(() => showReplaceAllButton = false));
              },
              text: "Platziere einen Stein",
            );
          }
        });
  }

  Widget actionButton({bool enabled = true, required String text, void Function()? onPressed, Color? color}) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)],
        borderRadius: BorderRadius.circular(40),
      ),
      child: TextButton(
        style: ButtonStyle(
          shape: MaterialStateProperty.all(RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(40),
          )),
          backgroundColor: MaterialStateProperty.all(color ?? Colors.black54),
          padding: MaterialStateProperty.all(const EdgeInsets.symmetric(horizontal: 40, vertical: 20)),
        ),
        onPressed: enabled ? onPressed : null,
        child: Text(
          text,
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
