import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../helpers/placement_helper.dart';
import '../../../models/game.dart';
import '../../../models/game_action.dart';
import '../../../models/token.dart';
import '../game_screen.dart';
import '../painters/board_painter.dart';
import '../painters/hint_painter.dart';
import '../painters/move_painter.dart';
import '../painters/placement_painter.dart';
import '../painters/token_painter_mixin.dart';

class QwirkleBoard extends StatefulWidget {
  static Key globalKey = GlobalKey();

  const QwirkleBoard(Key key) : super(key: key);

  @override
  QwirkleBoardState createState() => QwirkleBoardState();
}

class BoardTransform {
  Offset offset;
  double scale;
  BoardTransform(this.offset, this.scale);
}

class QwirkleBoardState extends State<QwirkleBoard> {
  ValueNotifier<BoardTransform> transform = ValueNotifier(BoardTransform(Offset.zero, 1.5));
  ValueNotifier<PlacementHint?> placementHint = ValueNotifier(null);

  @override
  void initState() {
    super.initState();
    GameScreen.of(context).board = this;
  }

  bool checkDropPosition(Offset offset, Token token) {
    var scenePos = toScenePos(offset);
    var pos = Pos(scenePos.dx.round(), scenePos.dy.round());

    var game = Provider.of<Game>(context, listen: false);
    if (game.board[pos] is TokenPlaceholder) {
      var action = PlacementAction(game.playerId, pos, token, false);
      var isValid = isValidPlacement(action, game.board, game.currentMove);

      placementHint.value = PlacementHint(pos, isValid);

      game.requestAction(action);
      return isValid;
    } else {
      game.requestAction(GameAction.removePlacement(game.playerId));

      placementHint.value = null;

      return false;
    }
  }

  Future<void> onDrop(Offset offset, Token token) async {
    var scenePos = toScenePos(offset);
    var pos = Pos(scenePos.dx.round(), scenePos.dy.round());

    var game = Provider.of<Game>(context, listen: false);
    await game.requestAction(PlacementAction(game.playerId, pos, token, true));

    placementHint.value = null;
  }

  Offset toTokenOffset(Offset offset) {
    var scenePos = toScenePos(offset);
    var pos = Pos(scenePos.dx.round(), scenePos.dy.round());
    return toGlobalOffset(pos);
  }

  void cancelDrop() {
    var game = Provider.of<Game>(context, listen: false);
    game.requestAction(GameAction.removePlacement(game.playerId));

    placementHint.value = null;
  }

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
          child: ValueListenableBuilder<BoardTransform>(
            valueListenable: transform,
            builder: (context, _, __) => Stack(
              children: [
                const Positioned.fill(child: AbsorbPointer()),
                buildBoard(),
                buildPlacementHint(),
                buildTokenPlacement(),
                buildMoveBorder(),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget buildBoard() {
    return buildCell(
      const Pos(0, 0),
      Selector<Game, Map<Pos, Cell>>(
        selector: (context, game) => game.board,
        builder: (context, board, _) => CustomPaint(
          painter: BoardPainter(board),
        ),
      ),
    );
  }

  Widget buildTokenPlacement() {
    return buildCell(
      const Pos(0, 0),
      Selector<Game, TokenPlacement?>(
        selector: (context, game) => game.currentPlayerId != game.playerId ? game.currentPlacement : null,
        builder: (context, placement, _) => CustomPaint(
          painter: PlacementPainter(placement),
        ),
      ),
    );
  }

  Widget buildMoveBorder() {
    return buildCell(
        const Pos(0, 0),
        Selector<Game, List<TokenPlacement>>(
          selector: (context, game) => game.currentMove,
          builder: (context, move, _) {
            return CustomPaint(
              painter: MovePainter(move),
            );
          },
        ));
  }

  Widget buildPlacementHint() {
    return buildCell(
      const Pos(0, 0),
      ValueListenableBuilder<PlacementHint?>(
        valueListenable: placementHint,
        builder: (context, hint, _) => CustomPaint(
          painter: HintPainter(hint),
        ),
      ),
    );
  }

  Widget buildCell(Pos pos, Widget child) {
    var offset = toGlobalOffset(pos);
    return Positioned(
      top: offset.dy,
      left: offset.dx,
      child: Transform.scale(
        scale: transform.value.scale,
        alignment: Alignment.topLeft,
        child: child,
      ),
    );
  }

  Offset toGlobalOffset(Pos pos) {
    var x = (pos.x * TokenPainterMixin.grid + transform.value.offset.dx) * transform.value.scale +
        boardCenter!.dx -
        TokenPainterMixin.grid / 2 * transform.value.scale;
    var y = (pos.y * TokenPainterMixin.grid + transform.value.offset.dy) * transform.value.scale +
        boardCenter!.dy -
        TokenPainterMixin.grid / 2 * transform.value.scale;
    return Offset(x, y);
  }

  Offset toScenePos(Offset pos) {
    var x = ((pos.dx - boardCenter!.dx) / transform.value.scale - transform.value.offset.dx) / TokenPainterMixin.grid;
    var y = ((pos.dy - boardCenter!.dy) / transform.value.scale - transform.value.offset.dy) / TokenPainterMixin.grid;
    return Offset(x, y);
  }

  void _receivedPointerSignal(PointerSignalEvent event) {
    if (event is PointerScrollEvent) {
      if (event.scrollDelta.dy == 0.0) {
        return;
      }
      double scaleChange = math.exp(-event.scrollDelta.dy / 200);
      double newScale = math.min(3, math.max(0.3, transform.value.scale * scaleChange));
      transform.value = BoardTransform(transform.value.offset, newScale);
    }
  }

  double? _scaleStart;
  Offset? _offsetStart;

  void _onScaleStart(ScaleStartDetails details) {
    _scaleStart = transform.value.scale;
    _offsetStart = details.localFocalPoint;
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    double newScale = transform.value.scale;
    Offset newOffset = transform.value.offset;
    if (details.scale != 1.0) {
      newScale = math.min(3, math.max(0.3, _scaleStart! * details.scale));
    } else {
      var delta = (details.localFocalPoint - _offsetStart!) / transform.value.scale;
      newOffset += delta;
      _offsetStart = details.localFocalPoint;
    }
    transform.value = BoardTransform(newOffset, newScale);
  }

  void _onScaleEnd(ScaleEndDetails details) {
    _scaleStart = null;
    _offsetStart = null;
  }
}
