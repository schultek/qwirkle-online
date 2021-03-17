import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/game.dart';
import '../../models/game_action.dart';
import '../../widgets/reorderable/draggable_manager.dart';
import '../../widgets/title_screen.dart';
import 'widgets/board.dart';
import 'widgets/finished_area.dart';
import 'widgets/play_area.dart';
import 'widgets/token_selector.dart';
import 'widgets/waiting_area.dart';

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
  late DraggableManager _reorderableManager;
  DraggableManager get reorderable => _reorderableManager;

  TokenSelectorState? tokenSelector;
  QwirkleBoardState? board;

  String? _nickname;
  bool isJoining = true;

  @override
  void initState() {
    super.initState();
    _reorderableManager = DraggableManager(this);

    widget.game.hasJoined().then((hasJoined) {
      if (hasJoined) {
        setState(() {
          isJoining = false;
        });
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    widget.game.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isJoining) {
      return buildJoinArea(context);
    }
    return Scaffold(
      body: ChangeNotifierProvider.value(
        value: widget.game,
        child: Container(
          color: Colors.grey.shade900,
          child: Center(
            child: Selector<Game, String>(
              selector: (context, game) => game.state,
              builder: (context, state, _) {
                return state == "waiting"
                    ? const WaitingArea()
                    : state == "running"
                        ? PlayArea()
                        : state == "finished"
                            ? FinishedArea()
                            : Container();
              },
            ),
          ),
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

  Widget buildJoinArea(BuildContext context) {
    return TitleScreen(
      Column(
        children: [
          TextField(
            decoration: InputDecoration(
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              hintText: "Nickname",
              hintStyle: const TextStyle(color: Colors.white),
            ),
            style: const TextStyle(color: Colors.white),
            onChanged: (text) {
              _nickname = text;
            },
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () async {
              if (_nickname == null) return;

              bool allowJoin =
                  await widget.game.requestAction(JoinAction(widget.game.playerId, _nickname!), sendDuplicate: true);
              if (allowJoin) {
                setState(() {
                  isJoining = false;
                });
              } else {
                print("NOT ALLOWED");
              }
            },
            style: ButtonStyle(
              backgroundColor: MaterialStateProperty.all(Colors.black),
              padding: MaterialStateProperty.all(const EdgeInsets.all(20)),
            ),
            child: const Text(
              "Beitreten",
              style: TextStyle(color: Colors.white),
            ),
          )
        ],
      ),
    );
  }
}
