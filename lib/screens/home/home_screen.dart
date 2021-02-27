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
      IntrinsicHeight(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () async {
                  Game game = await GameService.createGame();
                  QwirkleApp.of(context).open(GameRoutePath.join(game));
                },
                child: _asToken(
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
            const SizedBox(width: 20),
            _asToken(
              Center(
                child: TextField(
                  onSubmitted: (String id) async {
                    var game = await GameService.getGame(id);
                    QwirkleApp.of(context).open(GameRoutePath.join(game));
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
          ],
        ),
      ),
    );
  }

  Widget _asToken(Widget child) {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.all(10),
        child: child,
      ),
    );
  }
}
