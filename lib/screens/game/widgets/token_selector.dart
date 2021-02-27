import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../../models/game.dart';
import '../../../models/token.dart';
import '../../../widgets/reorderable/draggable_item.dart';
import '../game_screen.dart';
import 'token.dart';

class TokenSelector extends StatefulWidget {
  const TokenSelector();

  @override
  TokenSelectorState createState() => TokenSelectorState();

  static bool existsIn(BuildContext context) {
    return context.findAncestorStateOfType<TokenSelectorState>() != null;
  }
}

class TokenSelectorState extends State<TokenSelector> with TickerProviderStateMixin {
  late List<Cell> tokens;

  static double itemSize = 90;
  static double itemPadding = 10;
  double get leftEdge => (context.findRenderObject() as RenderBox).localToGlobal(Offset.zero).dx - 10;

  bool canDrag = false;

  GameScreenState get gameScreen => GameScreen.of(context);
  Game get game => gameScreen.game;

  @override
  void initState() {
    super.initState();

    gameScreen.tokenSelector = this;

    tokens = [...game.tokens.value];
    game.tokens.addListener(updateTokens);

    canDrag = game.currentPlayer.value == game.playerId;

    game.currentPlayer.addListener(() {
      setState(() {
        canDrag = game.currentPlayer.value == game.playerId;
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    var w = MediaQuery.of(context).size.width;
    print(w);
    if (w < 300) {
      itemSize = 50;
      itemPadding = 4;
    } else if (w < 800) {
      itemSize = 70;
      itemPadding = 6;
    } else {
      itemSize = 90;
      itemPadding = 8;
    }
  }

  @override
  void dispose() {
    super.dispose();
    game.tokens.removeListener(updateTokens);
  }

  void updateTokens() {
    var manager = GameScreen.of(context).reorderable;

    var oldTokens = [...tokens];
    var newTokens = [...game.tokens.value];

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

    setState(() {
      tokens = updatedTokens;
    });
  }

  void removeWidget(Token token) {
    var index = tokens.indexOf(token);

    setState(() {
      tokens[index] = TokenPlaceholder();
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
    if (tokens.isEmpty) return Container();
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 50),
        width: itemSize + itemPadding * 4,
        decoration: const BoxDecoration(
          color: Colors.black26,
          borderRadius: BorderRadius.horizontal(left: Radius.circular(20)),
        ),
        child: Padding(
          padding: EdgeInsets.all(itemPadding),
          child: AnimatedSize(
            vsync: this,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: MouseRegion(
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
                              placeholderBuilder: (_) => QwirkleToken.placeholder(),
                              child: QwirkleToken(token),
                            )
                          : QwirkleToken.placeholder(),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
