import 'dart:collection';
import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
// ignore: import_of_legacy_library_into_null_safe
import 'package:tuple/tuple.dart';

import '../../models/game_action.dart';
import '../../screens/game/game_screen.dart';
import '../../screens/game/widgets/board.dart';
import '../../screens/game/widgets/token.dart';
import '../../screens/game/widgets/token_selector.dart';
import 'draggable_item.dart';

class DraggableManager with Drag {
  GameScreenState gameScreenState;

  // Returns currently dragged key
  Key? get dragging => _dragging;

  Key? _dragging;
  Key? _maybeDragging;
  final Map<Key, DraggableItemState> _items = {};
  MultiDragGestureRecognizer? _recognizer;

  OverlayEntry? _entry;

  Offset? _dragOffset;
  double get dragSize => gameScreenState.board!.boardScale * QwirkleToken.size;
  Widget? _dragWidget;
  double? _dragDecorationOpacity;
  AnimationController? _dragScaleAnimation;

  AnimationController? _finalAnimation;

  bool _isOverWidgetSelector = false;
  bool _isDropAccepted = false;

  QwirkleBoardState? get board => gameScreenState.board;
  TokenSelectorState? get tokenSelector => gameScreenState.tokenSelector;

  DraggableManager(this.gameScreenState) {
    _dragScaleAnimation = AnimationController(
      vsync: gameScreenState,
      duration: const Duration(milliseconds: 200),
      value: 0,
    )..addListener(() {
        if (_entry != null) {
          _entry!.markNeedsBuild();
        }
      });
  }

  void dispose() {
    _finalAnimation?.dispose();
    for (var c in _itemTranslations.values) {
      c.item1?.dispose();
      c.item2?.dispose();
    }
    _recognizer?.dispose();
  }

  Widget _buildDragProxy(BuildContext context) {
    return Positioned.fromRect(
      rect: Rect.fromCenter(
        center: _dragOffset!,
        width: lerpDouble(TokenSelectorState.itemSize, dragSize, _dragScaleAnimation!.value)!,
        height: lerpDouble(TokenSelectorState.itemSize, dragSize, _dragScaleAnimation!.value)!,
      ),
      child: FittedBox(
        fit: BoxFit.fitHeight,
        child: MouseRegion(
          cursor: SystemMouseCursors.grabbing,
          child: SizedBox.fromSize(
            size: Size(dragSize, dragSize),
            child: gameScreenState.decorateItem(
              IgnorePointer(
                child: MediaQuery.removePadding(
                  context: context,
                  removeTop: true,
                  removeBottom: true,
                  child: _dragWidget!,
                ),
              ),
              _dragDecorationOpacity!,
            ),
          ),
        ),
      ),
    );
  }

  void startDragging({
    required Key key,
    required PointerDownEvent event,
    required MultiDragGestureRecognizer recognizer,
  }) {
    _finalAnimation?.stop();
    _finalAnimation?.dispose();
    _finalAnimation = null;

    if (_dragging != null) {
      var current = _items[_dragging];
      _dragging = null;
      current?.update();
    }

    _maybeDragging = key;
    _recognizer?.dispose();
    _recognizer = recognizer;
    _recognizer!.onStart = (position) => _dragStart(position);
    _recognizer!.addPointer(event);
  }

  Drag _dragStart(Offset position) {
    if (_dragging == null && _maybeDragging != null) {
      _dragging = _maybeDragging;
      _maybeDragging = null;
    }

    _hapticFeedback();

    var draggedItem = _items[_dragging]!;
    draggedItem.update();

    _dragWidget = draggedItem.widget.child;

    _dragDecorationOpacity = 1.0;

    _isDropAccepted = false;
    _dragScaleAnimation!.value = 0;
    _isOverWidgetSelector = true;

    var renderBox = draggedItem.context.findRenderObject() as RenderBox;

    _dragOffset =
        renderBox.localToGlobal(Offset.zero) + Offset(TokenSelectorState.itemSize / 2, TokenSelectorState.itemSize / 2);

    var overlayState = Overlay.of(gameScreenState.context)!;
    _entry = OverlayEntry(
      builder: (ctx) => _buildDragProxy(ctx),
    );
    overlayState.insert(_entry!);

    return this;
  }

  void draggedItemWidgetUpdated() {
    var draggedItem = _items[_dragging];
    if (draggedItem != null) {
      _dragWidget = draggedItem.widget.child;
      _entry!.markNeedsBuild();
    }
  }

  @override
  void update(DragUpdateDetails details) {
    if (_dragOffset == null || tokenSelector == null) return;
    _dragOffset = _dragOffset! + details.delta;

    if (details.globalPosition.dx < tokenSelector!.leftEdge) {
      if (_isOverWidgetSelector) {
        _isOverWidgetSelector = false;
        _dragScaleAnimation!.forward();
      }

      var accepted = board!.checkDropPosition(_dragOffset!, _items[dragging]!.widget.value);
      _isDropAccepted = accepted;
    } else {
      if (!_isOverWidgetSelector) {
        _isOverWidgetSelector = true;
        _dragScaleAnimation!.reverse();
        gameScreenState.game.requestAction(GameAction.removePlacement(gameScreenState.game.playerId));
      }
      if (_isDropAccepted) {
        _isDropAccepted = false;
        board!.cancelDrop(_dragging!);
      }
    }

    if (_entry != null) {
      _entry!.markNeedsBuild();
    }
  }

  @override
  Future<void> cancel() async {
    await end(null);
  }

  @override
  Future<void> end(DragEndDetails? details) async {
    if (_dragging == null) {
      return;
    }

    _hapticFeedback();

    var draggedItem = _items[_dragging];
    if (draggedItem == null) return;

    _finalAnimation = AnimationController(
      vsync: gameScreenState,
      value: 0.0,
      duration: const Duration(milliseconds: 300),
    );

    var dragOffset = _dragOffset;

    var dragScale = _dragScaleAnimation!.value;
    var targetScale = _isDropAccepted ? 1 : 0;

    var dropValue = _items[dragging]!.widget.value;
    _isDropAccepted &= gameScreenState.game.currentPlacement.value?.isAllowed ?? false;

    Offset targetOffset;
    if (_isDropAccepted) {
      targetOffset = board!.toTokenOffset(_dragOffset!);
    } else {
      var targetSize = TokenSelectorState.itemSize / 2;
      var renderBox = draggedItem.context.findRenderObject() as RenderBox;
      targetOffset = renderBox.localToGlobal(Offset.zero) + Offset(targetSize, targetSize);

      gameScreenState.game.requestAction(GameAction.removePlacement(gameScreenState.game.playerId));
    }

    _dragScaleAnimation!.stop();

    _finalAnimation!.addListener(() {
      _dragOffset = Offset.lerp(dragOffset, targetOffset, _finalAnimation!.value);
      _dragDecorationOpacity = 1.0 - _finalAnimation!.value;
      _dragScaleAnimation!.value = lerpDouble(dragScale, targetScale, _finalAnimation!.value)!;
      _entry!.markNeedsBuild();
    });

    _recognizer?.dispose();
    _recognizer = null;

    await _finalAnimation!.animateTo(1.0, curve: Curves.easeOut);

    if (_finalAnimation != null) {
      _finalAnimation!.dispose();
      _finalAnimation = null;

      if (_isDropAccepted) {
        tokenSelector!.removeWidget(dropValue);
        await board!.onDrop(_dragOffset!, dropValue);
      }

      _dragging = null;
      _onDragFinished();
      draggedItem.update();
    }
  }

  void _onDragFinished() {
    _entry!.remove();
    _entry = null;
  }

  void _hapticFeedback() {
    HapticFeedback.lightImpact();
  }

  void registerItem(DraggableItemState item) {
    _items[item.key] = item;
  }

  void unregisterItem(DraggableItemState item) {
    if (_items[item.key] == item) _items.remove(item.key);
  }

  Offset _itemOffset(DraggableItemState item) {
    return (item.context.findRenderObject() as RenderBox).localToGlobal(Offset.zero);
  }

  Offset itemOffset(Key key) {
    return _itemOffset(_items[key]!);
  }

  Size itemSize(Key key) {
    return _items[key]!.context.size!;
  }

  //

  final Map<Key, Tuple2<AnimationController?, AnimationController?>> _itemTranslations = HashMap();
  final Map<Key, bool> _itemFadeIn = HashMap();

  Offset itemTranslation(Key key) {
    if (!_itemTranslations.containsKey(key)) {
      return Offset.zero;
    } else {
      var tuple = _itemTranslations[key]!;
      return Offset(
        tuple.item1?.value ?? 0.0,
        tuple.item2?.value ?? 0.0,
      );
    }
  }

  double fadeOpacity(Key key) {
    if (!_itemTranslations.containsKey(key) || _itemTranslations[key]!.item1 == null) {
      return 1;
    } else {
      var animation = _itemTranslations[key]!.item1!;
      return (animation.value - animation.lowerBound) / (animation.upperBound - animation.lowerBound);
    }
  }

  void translateItemY(Key key, double delta) {
    double current = 0.0;
    double max = delta.abs();
    if (_itemTranslations.containsKey(key)) {
      var currentController = _itemTranslations[key]!.item2;
      if (currentController != null) {
        current = currentController.value;
        currentController.stop();
        currentController.dispose();
      }
    }

    current += delta;

    var newController = AnimationController(
      vsync: gameScreenState,
      lowerBound: current < 0.0 ? -max : 0.0,
      upperBound: current < 0.0 ? 0.0 : max,
      value: current,
      duration: const Duration(milliseconds: 300),
    );
    newController.addListener(() {
      _items[key]?.update(); // update offset
    });
    newController.addStatusListener((AnimationStatus s) {
      if (s == AnimationStatus.completed || s == AnimationStatus.dismissed) {
        newController.dispose();
        if (_itemTranslations[key]!.item2 == newController) {
          setItemTranslationY(key, null);
        }
      }
    });
    setItemTranslationY(key, newController);

    newController.animateTo(0.0, curve: Curves.easeInOut);
  }

  void setItemTranslationY(Key key, AnimationController? controller) {
    if (_itemTranslations.containsKey(key)) {
      _itemTranslations[key] = Tuple2(_itemTranslations[key]!.item1, controller);
    } else {
      _itemTranslations[key] = Tuple2(null, controller);
    }
  }

  void translateItemX(Key key, double delta, {bool fadeIn = false}) {
    double current = 0.0;
    double max = delta.abs();
    if (_itemTranslations.containsKey(key)) {
      var currentController = _itemTranslations[key]!.item1;
      if (currentController != null) {
        current = currentController.value;
        currentController.stop();
        currentController.dispose();
      }
    }

    current += delta;

    var newController = AnimationController(
      vsync: gameScreenState,
      lowerBound: current < 0.0 ? -max : 0.0,
      upperBound: current < 0.0 ? 0.0 : max,
      value: current,
      duration: const Duration(milliseconds: 300),
    );
    newController.addListener(() {
      _items[key]?.update(); // update offset
    });
    newController.addStatusListener((AnimationStatus s) {
      if (s == AnimationStatus.completed || s == AnimationStatus.dismissed) {
        newController.dispose();
        if (_itemTranslations[key]!.item1 == newController) {
          setItemTranslationX(key, null);
        }
      }
    });
    setItemTranslationX(key, newController);
    _itemFadeIn[key] = fadeIn;

    newController.animateTo(0.0, curve: Curves.easeInOut);
  }

  void setItemTranslationX(Key key, AnimationController? controller) {
    if (_itemTranslations.containsKey(key)) {
      _itemTranslations[key] = Tuple2(controller, _itemTranslations[key]!.item2);
    } else {
      _itemTranslations[key] = Tuple2(controller, null);
    }
  }
}
