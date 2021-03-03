// ignore: import_of_legacy_library_into_null_safe
import 'package:clipboard/clipboard.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/game.dart';
import '../../../models/painters.dart';

class WaitingArea extends StatelessWidget {
  const WaitingArea();

  @override
  Widget build(BuildContext context) {
    return Selector<Game, Iterable<Player>>(
      selector: (context, game) => game.players.values,
      builder: (context, players, _) => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            "Spieler",
            style: TextStyle(
              color: Colors.white,
              fontSize: 40,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          ...ListTile.divideTiles(
            context: context,
            tiles: players.map((player) {
              return IntrinsicWidth(
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 5),
                  leading: CircleAvatar(
                    backgroundColor: SymbolPainter.colorFromTag(player.color),
                    radius: 18,
                    child: Text(
                      player.nickname[0],
                      style: const TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  title:
                      Text(player.nickname, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              );
            }),
            color: Colors.white38,
          ),
          const SizedBox(height: 40),
          OutlinedButton(
            onPressed: () async {
              await FlutterClipboard.copy(Uri.base.toString().replaceFirst("/game/", "/join/"));
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                backgroundColor: Colors.green,
                content: Text("In Zwischenablage kopiert"),
              ));
            },
            style: ButtonStyle(
              padding: MaterialStateProperty.all(const EdgeInsets.symmetric(vertical: 15, horizontal: 20)),
              side: MaterialStateProperty.all(const BorderSide(color: Colors.blue)),
              shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
              foregroundColor: MaterialStateProperty.all(Colors.blue),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(Uri.base.toString().replaceFirst("/game/", "/join/"), style: const TextStyle(color: Colors.blue)),
                const SizedBox(width: 10),
                const Icon(
                  Icons.copy,
                  color: Colors.blue,
                  size: 15,
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          if (Provider.of<Game>(context, listen: false).isGameMaster)
            TextButton(
              onPressed: () => Provider.of<Game>(context, listen: false).startGame(),
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all(Colors.black),
                padding: MaterialStateProperty.all(const EdgeInsets.all(30)),
                shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              ),
              child: const Text(
                "Spiel Starten",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
