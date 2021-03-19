import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../main.dart';
import '../../models/game.dart';
import '../../router/game_route_path.dart';
import '../../services/game_service.dart';
import '../../widgets/title_screen.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return TitleScreen(
      AspectRatio(
        aspectRatio: 4,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            TitleScreen.asToken(Container(), Colors.grey.shade800.withOpacity(0.1)),
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () async {
                  try {
                    Game game = await GameService.createGame();
                    QwirkleApp.of(context).open(GameRoutePath.game(game));
                  } catch (e) {
                    print(e);
                  }
                },
                child: TitleScreen.asToken(
                  const Center(
                    child: Text(
                      "Neues\nSpiel",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 25,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
            TitleScreen.asToken(
              Center(
                child: TextField(
                  onSubmitted: (String id) async {
                    var game = await GameService.getGame(id);
                    QwirkleApp.of(context).open(GameRoutePath.game(game));
                  },
                  decoration: InputDecoration(
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    hintText: "Code eingeben",
                    hintStyle: const TextStyle(color: Colors.white),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
            TitleScreen.asToken(Container(), Colors.grey.shade800.withOpacity(0.1)),
          ],
        ),
      ),
    );
  }
}
