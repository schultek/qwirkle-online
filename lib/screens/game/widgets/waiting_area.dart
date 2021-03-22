// ignore: import_of_legacy_library_into_null_safe
import 'package:clipboard/clipboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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
            const Text(
              "Modus Auswählen:",
              style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
            ),
          if (Provider.of<Game>(context, listen: false).isGameMaster)
            Selector<Game, String>(
              selector: (context, game) => game.mode,
              builder: (context, mode, _) => Padding(
                padding: const EdgeInsets.only(bottom: 30),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _modeButton(context, "Normal", "normal", mode),
                        _modeButton(context, "Infinity", "infinity", mode),
                        _modeButton(context, "Schwer", "hard", mode),
                      ],
                    ),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 400),
                      child: Text(
                        mode == "normal"
                            ? "144 Steine. Das Spiel endet wenn alle Steine aufgebraucht sind. Der Spieler mit den meisten Punkten gewinnt."
                            : mode == "infinity"
                                ? "Unendlich viele Steine, unendlich viel Zeit, spiel ohne Ende."
                                : "Ein Spielstein weniger mit jedem Qwirkel. Das Spiel endet wenn der erste Spieler keine Steine mehr übrig hat. Der Spieler mit den meisten Punkten gewinnt.",
                        style: const TextStyle(color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
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

  Widget _modeButton(BuildContext context, String label, String mode, String currentMode) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () async {
            Provider.of<Game>(context, listen: false).gameRef.child("mode").set(mode);
          },
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(10),
              border: mode == currentMode ? Border.all(color: Colors.green) : null,
            ),
            padding: const EdgeInsets.all(10),
            child: Center(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
