import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../models/board.dart';
import '../../../models/game.dart';
import '../../../models/game_action.dart';
import '../../../models/token.dart';
import '../../../models/value_subscription.dart';
import '../game_screen.dart';
import 'token.dart';

class TokenMove {
  Token token;
  Pos pos;
  bool isAllowed;
  TokenMove(this.pos, this.token, this.isAllowed);
}

class QwirkleBoard extends StatefulWidget {
  final Game game;
  const QwirkleBoard(this.game);

  @override
  QwirkleBoardState createState() => QwirkleBoardState();
}

class QwirkleBoardState extends State<QwirkleBoard> {
  Game get game => widget.game;
  ValueSubscription<Board> get board => game.board;

  Offset boardOffset = Offset.zero;
  double boardScale = 1.5;

  @override
  void initState() {
    super.initState();
    GameScreen.of(context).board = this;

    game.currentPlacement.addListener(update);
    game.board.addListener(update);
    game.currentMove.addListener(update);
  }

  @override
  void dispose() {
    super.dispose();
    game.currentPlacement.removeListener(update);
    game.board.removeListener(update);
    game.currentMove.removeListener(update);
  }

  void update() {
    setState(() {});
  }

  bool checkDropPosition(Offset offset, Token token) {
    var scenePos = toScenePos(offset);
    var pos = Pos(scenePos.dx.round(), scenePos.dy.round());
    if (board.value.board[pos] is TokenPlaceholder) {
      game.requestAction(PlacementAction(game.playerId, pos, token, false));
      return true;
    } else {
      game.requestAction(GameAction.removePlacement(game.playerId));
      return false;
    }
  }

  Future<void> onDrop(Offset offset, Token token) async {
    var scenePos = toScenePos(offset);
    var pos = Pos(scenePos.dx.round(), scenePos.dy.round());
    await game.requestAction(PlacementAction(game.playerId, pos, token, true));
  }

  Offset toTokenOffset(Offset offset) {
    var scenePos = toScenePos(offset);
    var pos = Pos(scenePos.dx.round(), scenePos.dy.round());
    return toGlobalOffset(pos) + const Offset(QwirkleToken.size / 2, QwirkleToken.size / 2);
  }

  void cancelDrop(Key key) {}

  Offset? boardCenter;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      boardCenter = Offset(constraints.maxWidth / 2, constraints.maxHeight / 2);
      return Listener(
        onPointerSignal: _receivedPointerSignal,
        child: GestureDetector(
          onScaleStart: _onScaleStart,
          onScaleUpdate: _onScaleUpdate,
          onScaleEnd: _onScaleEnd,
          child: Stack(
            children: [
              const Positioned.fill(child: AbsorbPointer()),
              ...game.board.value.map((pos, cell) => buildCell(
                    pos,
                    cell is Token ? QwirkleToken(cell) : QwirkleToken.placeholder(),
                  )),
              if (game.currentPlacement.value != null)
                buildCell(
                  game.currentPlacement.value!.pos,
                  game.currentPlayer.value == game.playerId
                      ? QwirkleToken.placeholder(game.currentPlacement.value!.isAllowed ? Colors.green : Colors.red)
                      : Opacity(
                          opacity: 0.5,
                          child: QwirkleToken(game.currentPlacement.value!.token),
                        ),
                ),
              if (game.currentMove.value != null) ...buildMoveBorder(game.currentMove.value!.placements),
            ],
          ),
        ),
      );
    });
  }

  Widget buildCell(Pos pos, Widget child) {
    var offset = toGlobalOffset(pos);
    return Positioned(
      top: offset.dy,
      left: offset.dx,
      child: Transform.scale(
        scale: boardScale,
        child: child,
      ),
    );
  }

  Offset toGlobalOffset(Pos pos) {
    var x = (pos.x * QwirkleToken.size + boardOffset.dx) * boardScale + boardCenter!.dx - QwirkleToken.size / 2;
    var y = (pos.y * QwirkleToken.size + boardOffset.dy) * boardScale + boardCenter!.dy - QwirkleToken.size / 2;
    return Offset(x, y);
  }

  Offset toScenePos(Offset pos) {
    var x = ((pos.dx - boardCenter!.dx) / boardScale - boardOffset.dx) / QwirkleToken.size;
    var y = ((pos.dy - boardCenter!.dy) / boardScale - boardOffset.dy) / QwirkleToken.size;
    return Offset(x, y);
  }

  void _receivedPointerSignal(PointerSignalEvent event) {
    if (event is PointerScrollEvent) {
      if (event.scrollDelta.dy == 0.0) {
        return;
      }
      double scaleChange = math.exp(-event.scrollDelta.dy / 200);
      boardScale *= scaleChange;
      setState(() {
        boardScale = math.min(3, math.max(0.3, boardScale));
      });
    }
  }

  double? _scaleStart;
  Offset? _offsetStart;

  void _onScaleStart(ScaleStartDetails details) {
    _scaleStart = boardScale;
    _offsetStart = details.localFocalPoint;
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    if (details.scale != 1.0) {
      boardScale = _scaleStart! * details.scale;
    } else {
      var delta = (details.localFocalPoint - _offsetStart!) / boardScale;
      boardOffset += delta;
      _offsetStart = details.localFocalPoint;
    }
    setState(() {
      boardScale = math.min(3, math.max(0.3, boardScale));
    });
  }

  void _onScaleEnd(ScaleEndDetails details) {
    _scaleStart = null;
    _offsetStart = null;
  }

  List<Widget> buildMoveBorder(List<TokenPlacement> placements) {
    return placements.map((p) {
      return buildCell(
        p.pos,
        QwirkleToken.placeholder(Colors.green.withOpacity(0.5), Colors.transparent),
      );
    }).toList();
  }
}
