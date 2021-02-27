import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../models/token.dart';
import '../../screens/game/game_screen.dart';
import 'draggable_manager.dart';

enum ReorderableState { normal, placeholder, dragging }

class DraggableItem extends StatefulWidget {
  const DraggableItem({
    required Key key,
    required this.value,
    required this.placeholderBuilder,
    required this.child,
  }) : super(key: key);

  final Token value;
  final Widget child;
  final WidgetBuilder placeholderBuilder;

  @override
  DraggableItemState createState() => DraggableItemState();
}

class DraggableItemState extends State<DraggableItem> {
  DraggableManager? _manager;

  Key get key => widget.key!;

  @override
  Widget build(BuildContext context) {
    _manager = GameScreen.of(context).reorderable;
    _manager!.registerItem(this);

    Widget child;
    if (_manager!.dragging == key) {
      child = widget.placeholderBuilder(context);
    } else {
      child = MouseRegion(
        cursor: SystemMouseCursors.grab,
        child: Listener(
          onPointerDown: _startDragging,
          child: AbsorbPointer(
            child: widget.child,
          ),
        ),
      );
    }

    Offset translation = _manager!.itemTranslation(key);
    double opacity = _manager!.fadeOpacity(key);
    return Transform(
      transform: Matrix4.translationValues(translation.dx, translation.dy, 0.0),
      child: Opacity(opacity: opacity, child: child),
    );
  }

  @override
  void didUpdateWidget(DraggableItem oldWidget) {
    super.didUpdateWidget(oldWidget);

    _manager = GameScreen.of(context).reorderable;
    if (_manager!.dragging == key) {
      _manager!.draggedItemWidgetUpdated();
    }
  }

  void update() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void deactivate() {
    _manager?.unregisterItem(this);
    _manager = null;
    super.deactivate();
  }

  void _startDragging(PointerDownEvent event) {
    var manager = GameScreen.of(context).reorderable;

    if (manager.dragging == null) {
      manager.startDragging(
        key: key,
        event: event,
        recognizer: DelayedMultiDragGestureRecognizer(
          delay: kIsWeb ? Duration.zero : const Duration(milliseconds: 200),
          debugOwner: this,
          kind: event.kind,
        ),
      );
    }
  }
}
