import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/game.dart';
import 'player_avatar.dart';

class ScoreBoard extends StatefulWidget {
  const ScoreBoard();

  @override
  _ScoreBoardState createState() => _ScoreBoardState();
}

class _ScoreBoardState extends State<ScoreBoard> {
  bool scoreBoardHovered = false;
  bool persistentScoreBoard = true;

  @override
  Widget build(BuildContext context) {
    print("BUILD SCORE BOARD");
    return AnimatedPositioned(
      left: persistentScoreBoard || scoreBoardHovered ? 0 : -140,
      top: 0,
      bottom: 0,
      duration: const Duration(milliseconds: 300),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 50),
          width: 170,
          decoration: const BoxDecoration(
            color: Colors.black26,
            borderRadius: BorderRadius.horizontal(right: Radius.circular(20)),
          ),
          child: Padding(
            padding: const EdgeInsets.only(left: 15, top: 5, bottom: 5),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                  child: Selector<Game, Iterable<Player>>(
                    selector: (context, game) => game.players.values,
                    builder: (context, players, _) => Column(
                      mainAxisSize: MainAxisSize.min,
                      children: ListTile.divideTiles(
                              context: context,
                              tiles: players.map((p) {
                                return playerTile(p);
                              }).toList(),
                              color: Colors.white24)
                          .toList(),
                    ),
                  ),
                ),
                InkWell(
                  onTap: () {
                    setState(() {
                      persistentScoreBoard = !persistentScoreBoard;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      persistentScoreBoard ? Icons.chevron_left : Icons.chevron_right,
                      color: Colors.white38,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget playerTile(Player player) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 10),
      leading: PlayerAvatar(player),
      title: Text(player.nickname, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 2),
          Text("${player.points} Punkte", style: const TextStyle(color: Colors.white)),
          const SizedBox(height: 2),
          Row(
            children: List.filled(
              player.tokens.length,
              Container(
                margin: const EdgeInsets.only(right: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(2),
                ),
                width: 8,
                height: 8,
              ),
              growable: true,
            )..addAll(List.filled(
                player.tokenCount - player.tokens.length,
                Container(
                  margin: const EdgeInsets.only(right: 4),
                  decoration: BoxDecoration(
                    color: Colors.white38,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  width: 8,
                  height: 8,
                ),
              )),
          )
        ],
      ),
    );
  }
}
