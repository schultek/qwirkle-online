import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:qwirkle_online/screens/game/painters/token_painter_mixin.dart';

import '../../../models/game.dart';
import '../../../models/token.dart';
import '../../../widgets/reorderable/draggable_item.dart';
import '../game_screen.dart';
import '../painters/cell_painter.dart';

class TokenSelector extends StatefulWidget {
  const TokenSelector();

  @override
  TokenSelectorState createState() => TokenSelectorState();

  static bool existsIn(BuildContext context) {
    return context.findAncestorStateOfType<TokenSelectorState>() != null;
  }
}

class TokenSelectorState extends State<TokenSelector> with TickerProviderStateMixin {
  late List<Cell> _localTokens;

  static double itemSize = 90;
  static double itemPadding = 10;
  double get leftEdge => (context.findRenderObject() as RenderBox).localToGlobal(Offset.zero).dx - 10;

  GameScreenState get gameScreen => GameScreen.of(context);

  @override
  void initState() {
    super.initState();

    gameScreen.tokenSelector = this;

    var game = Provider.of<Game>(context, listen: false);

    _localTokens = [...game.myPlayer.tokens];
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    var size = MediaQuery.of(context).size;
    if (size.width < 600 || size.height < 550) {
      itemSize = 50;
      itemPadding = 4;
    } else if (size.width < 800 || size.height < 650) {
      itemSize = 70;
      itemPadding = 6;
    } else {
      itemSize = 90;
      itemPadding = 8;
    }
  }

  List<Cell> getUpdatedTokens(Game game) {
    var manager = GameScreen.of(context).reorderable;

    var oldTokens = [..._localTokens];
    var newTokens = [...game.myPlayer.tokens];

    var tokenCount = game.myPlayer.tokenCount;

    var updatedTokens = <Cell>[];

    for (var token in oldTokens) {
      if (token is TokenPlaceholder) {
        updatedTokens.add(token);
      } else if (newTokens.contains(token)) {
        updatedTokens.add(token);
        newTokens.remove(token);
      }
    }

    for (var token in newTokens) {
      var i = updatedTokens.indexWhere((t) => t is TokenPlaceholder);
      if (i != -1) {
        updatedTokens[i] = token;
        manager.translateItemX(token.key, -itemSize, fadeIn: true);
      } else {
        updatedTokens.add(token);
      }
    }

    while (updatedTokens.length > tokenCount) {
      var index = updatedTokens.indexWhere((t) => t is TokenPlaceholder);
      updatedTokens.removeAt(index);
    }

    _localTokens = updatedTokens;
    return updatedTokens;
  }

  void removeWidget(Token token) {
    var index = _localTokens.indexOf(token);
    WidgetsBinding.instance!.addPostFrameCallback((timeStamp) {
      setState(() {
        _localTokens[index] = TokenPlaceholder();
      });
    });

    // var manager = GameScreen.of(context).reorderable;
    //
    // for (int i = 0; i < tokens.length; i++) {
    //   if (i == index) continue;
    //   var sign = i < index ? -1 : 1;
    //   manager.translateItemY(tokens[i].key, sign * (itemSize / 2 + itemPadding));
    // }
    //
    // setState(() {
    //   tokens.remove(token);
    // });

    // Future.delayed(const Duration(milliseconds: 100), () {
    //   addToken(index, Token(Token.randomTag()));
    // });
  }

  @override
  Widget build(BuildContext context) {
    return Selector<Game, List<Cell>>(
      selector: (context, game) => getUpdatedTokens(game),
      builder: (context, tokens, _) {
        if (tokens.isEmpty) return Container();
        return Center(
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 50),
            width: itemSize + itemPadding * 4,
            decoration: const BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.horizontal(left: Radius.circular(20)),
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(20)),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Padding(
                  padding: EdgeInsets.all(itemPadding),
                  child: AnimatedSize(
                    vsync: this,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    child: Selector<Game, bool>(
                      selector: (context, game) => game.currentPlayerId == game.playerId,
                      builder: (context, canDrag, _) => MouseRegion(
                        cursor: canDrag ? SystemMouseCursors.basic : SystemMouseCursors.forbidden,
                        child: IgnorePointer(
                          ignoring: !canDrag,
                          child: ListView(
                            shrinkWrap: true,
                            physics: const ClampingScrollPhysics(),
                            children: tokens.map((token) {
                              return Padding(
                                padding: EdgeInsets.all(itemPadding),
                                child: token is Token
                                    ? DraggableItem(
                                        key: token.key,
                                        value: token,
                                        placeholderBuilder: (_) => buildCell(TokenPlaceholder()),
                                        child: buildCell(token),
                                      )
                                    : buildCell(token),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget buildCell(Cell cell) {
    return FittedBox(
      child: SizedBox(
        width: TokenPainterMixin.grid,
        height: TokenPainterMixin.grid,
        child: CustomPaint(
          painter: CellPainter(cell),
        ),
      ),
    );
  }
}
