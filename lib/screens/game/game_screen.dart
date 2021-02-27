import 'package:flutter/material.dart';

import '../../models/game.dart';
import '../../models/game_action.dart';
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
        ListView.builder(
          shrinkWrap: true,
          itemCount: game.players.value.length,
          itemBuilder: (context, index) {
            return Text(
              game.players.value[index].nickname,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
              ),
            );
          },
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
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          child: buildScoreBoard(),
        ),
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
      ],
    );
  }

  Widget buildScoreBoard() {
    return Container();
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
