import 'package:clipboard/clipboard.dart';
import 'package:flutter/material.dart';
import 'package:tuple/tuple.dart';

import '../../models/game.dart';
import '../../models/game_action.dart';
import '../../models/painters.dart';
import '../../widgets/reorderable/draggable_manager.dart';
import 'widgets/board.dart';
import 'widgets/token_selector.dart';

class GameScreen extends StatefulWidget {
  final Game game;
  const GameScreen(this.game);

  @override
  GameScreenState createState() => GameScreenState();

  static GameScreenState of(BuildContext context) {
    return context.findAncestorStateOfType()!;
  }
}

class GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  Game get game => widget.game;

  late DraggableManager _reorderableManager;
  DraggableManager get reorderable => _reorderableManager;

  TokenSelectorState? tokenSelector;
  QwirkleBoardState? board;

  bool showReplaceAllButton = false;
  bool scoreBoardHovered = false;
  bool persistentScoreBoard = true;

  @override
  void initState() {
    super.initState();

    game.state.addListener(update);
    game.players.addListener(update);
    game.currentPlayer.addListener(update);
    game.currentMove.addListener(update);

    _reorderableManager = DraggableManager(this);
  }

  @override
  void dispose() {
    super.dispose();
    game.dispose();
  }

  void update() {
    showReplaceAllButton = false;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: buildTable(
        child: game.state.value == "waiting"
            ? buildWaitingArea()
            : game.state.value == "running"
                ? buildPlayArea()
                : Container(),
      ),
    );
  }

  Widget buildTable({required Widget child}) {
    return Container(
      color: Colors.grey.shade900,
      child: Center(child: child),
    );
  }

  Widget buildWaitingArea() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          "Spieler",
          style: TextStyle(
            color: Colors.white,
            fontSize: 40,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 20),
        ...ListTile.divideTiles(
          context: context,
          tiles: game.players.value.map((player) {
            return IntrinsicWidth(
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(vertical: 5),
                leading: CircleAvatar(
                  backgroundColor: SymbolPainter.colorFromTag(player.color),
                  radius: 18,
                  child: Text(
                    player.nickname[0],
                    style: const TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text(player.nickname, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            );
          }),
          color: Colors.white38,
        ),
        const SizedBox(height: 40),
        OutlinedButton(
          onPressed: () async {
            await FlutterClipboard.copy(Uri.base.toString().replaceFirst("/game/", "/join/"));
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              backgroundColor: Colors.green,
              content: Text("In Zwischenablage kopiert"),
            ));
          },
          style: ButtonStyle(
            padding: MaterialStateProperty.all(const EdgeInsets.symmetric(vertical: 15, horizontal: 20)),
            side: MaterialStateProperty.all(const BorderSide(color: Colors.blue)),
            shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
            foregroundColor: MaterialStateProperty.all(Colors.blue),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(Uri.base.toString().replaceFirst("/game/", "/join/"), style: const TextStyle(color: Colors.blue)),
              const SizedBox(width: 10),
              const Icon(
                Icons.copy,
                color: Colors.blue,
                size: 15,
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),
        if (game.isGameMaster)
          TextButton(
            onPressed: () => game.startGame(),
            style: ButtonStyle(
              backgroundColor: MaterialStateProperty.all(Colors.black),
              padding: MaterialStateProperty.all(const EdgeInsets.all(30)),
              shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            ),
            child: const Text(
              "Spiel Starten",
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  Widget buildPlayArea() {
    return Stack(
      children: [
        Positioned.fill(child: QwirkleBoard(game)),
        const Positioned(
          right: 0,
          top: 0,
          bottom: 0,
          child: TokenSelector(),
        ),
        buildScoreBoard(),
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
                  game.requestAction(GameAction.replaceTokens(game.playerId));
                },
                text: "Ersetze alle Steine",
                color: Colors.orange,
              ),
            ),
          ),
        ),
        if (game.currentPlayer.value == game.playerId)
          Positioned(
            left: 0,
            right: 0,
            bottom: 50,
            child: Center(child: buildPlayerActions()),
          ),
        Positioned(
          top: 70,
          left: 0,
          right: 0,
          child: Center(
            child: StreamBuilder<Tuple2<String, String>>(
              stream: game.messages,
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

  Widget buildScoreBoard() {
    return AnimatedPositioned(
      left: persistentScoreBoard || scoreBoardHovered ? 0 : -140,
      top: 0,
      bottom: 0,
      duration: const Duration(milliseconds: 300),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 50),
          width: 170,
          decoration: const BoxDecoration(
            color: Colors.black26,
            borderRadius: BorderRadius.horizontal(right: Radius.circular(20)),
          ),
          child: Padding(
            padding: const EdgeInsets.only(left: 15, top: 5, bottom: 5),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: ListTile.divideTiles(
                            context: context,
                            tiles: game.players.value.map((p) {
                              return playerAvatar(p);
                            }).toList(),
                            color: Colors.white24)
                        .toList(),
                  ),
                ),
                InkWell(
                  onTap: () {
                    setState(() {
                      persistentScoreBoard = !persistentScoreBoard;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      persistentScoreBoard ? Icons.chevron_left : Icons.chevron_right,
                      color: Colors.white38,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget playerAvatar(Player player) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 0),
      leading: CircleAvatar(
        backgroundColor: SymbolPainter.colorFromTag(player.color),
        radius: 18,
        child: Text(
          player.nickname[0],
          style: const TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      title: Text(player.nickname, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 2),
          Text("${player.points} Punkte", style: const TextStyle(color: Colors.white)),
          const SizedBox(height: 2),
          Row(
            children: List.filled(
              player.tokens.length,
              Container(
                margin: const EdgeInsets.only(right: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(2),
                ),
                width: 8,
                height: 8,
              ),
              growable: true,
            )..addAll(List.filled(
                player.tokenCount - player.tokens.length,
                Container(
                  margin: const EdgeInsets.only(right: 4),
                  decoration: BoxDecoration(
                    color: Colors.white38,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  width: 8,
                  height: 8,
                ),
              )),
          )
        ],
      ),
    );
  }

  Widget buildPlayerHint() {
    var text = game.currentPlayer.value == game.playerId
        ? "Du bist"
        : "${game.players.value.firstWhere((p) => p.id == game.currentPlayer.value).nickname} ist";
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: Colors.green),
        color: Colors.black12,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Text(
        "$text am Zug",
        style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget buildPlayerActions() {
    if (game.currentMove.value?.placements.isEmpty ?? true) {
      return actionButton(
        onPressed: () {
          setState(() => showReplaceAllButton = true);
          Future.delayed(const Duration(seconds: 2), () => setState(() => showReplaceAllButton = false));
        },
        text: "Platziere einen Stein",
      );
    } else {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          actionButton(
            onPressed: () {
              game.requestAction(GameAction.back(game.playerId), sendDuplicate: true);
            },
            color: Colors.grey,
            text: "Zurück",
          ),
          const SizedBox(width: 20),
          actionButton(
            onPressed: () {
              game.requestAction(GameAction.finish(game.playerId));
            },
            color: Colors.green,
            text: "Fertig",
          ),
        ],
      );
    }
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

  Widget decorateItem(Widget widget, double opacity) {
    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), boxShadow: [
        BoxShadow(
          blurRadius: 8,
          spreadRadius: -2,
          color: Colors.black.withOpacity(opacity * 0.5),
        )
      ]),
      child: widget,
    );
  }
}
