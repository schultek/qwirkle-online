import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/game.dart';
import '../../widgets/reorderable/draggable_manager.dart';
import 'widgets/board.dart';
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

  @override
  void initState() {
    super.initState();
    _reorderableManager = DraggableManager(this);
  }

  @override
  void dispose() {
    super.dispose();
    widget.game.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
}
