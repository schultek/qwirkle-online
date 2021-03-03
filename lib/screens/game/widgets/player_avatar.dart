import 'package:flutter/material.dart';

import '../../../models/game.dart';
import '../../../models/painters.dart';

class PlayerAvatar extends StatelessWidget {
  final Player player;
  const PlayerAvatar(this.player);

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      backgroundColor: SymbolPainter.colorFromTag(player.color),
      radius: 18,
      child: Text(
        player.nickname[0],
        style: const TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }
}
