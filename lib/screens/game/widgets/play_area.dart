import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// ignore: import_of_legacy_library_into_null_safe
import 'package:tuple/tuple.dart';

import '../../../models/game.dart';
import '../../../models/game_action.dart';
import 'board.dart';
import 'score_board.dart';
import 'token_selector.dart';

class PlayArea extends StatefulWidget {
  @override
  _PlayAreaState createState() => _PlayAreaState();
}

class _PlayAreaState extends State<PlayArea> {
  bool showReplaceAllButton = false;

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
            }),
        Positioned(
          top: 70,
          left: 0,
          right: 0,
          child: Center(
            child: StreamBuilder<Tuple2<String, String>>(
              stream: Provider.of<Game>(context, listen: false).messages,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return TweenAnimationBuilder<double>(
                    key: ValueKey(snapshot.data!.item1),
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
                          snapshot.data!.item2,
                          style: const TextStyle(color: Colors.green, fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      );
                    },
                  );
                } else {
                  return Container();
                }
              },
            ),
          ),
        )
      ],
    );
  }

  Widget buildPlayerHint() {
    return Container(
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
