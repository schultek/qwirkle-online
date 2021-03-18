import 'dart:async';
import 'dart:math';

// ignore: import_of_legacy_library_into_null_safe
import 'package:firebase/firebase.dart';

import '../models/game.dart';
import 'auth_service.dart';

class GameService {
  static Database get db => database();

  static final Map<String, Game> games = {};

  static Future<Game> getGame(String gameId) async {
    return games[gameId] ??= await Game.setup(gameId, await AuthService.getUserId());
  }

  static Future<Game> createGame() async {
    String gameId = "000000${Random().nextInt(100000)}";
    gameId = gameId.substring(gameId.length - 6);

    removeOldGames();

    var gameRef = db.ref("games/$gameId");

    await gameRef.set({
      "creatorUserId": await AuthService.getUserId(),
      "state": "waiting",
      "currentPlayerId": null,
      "players": {},
      "lastHeartbeat": ServerValue.TIMESTAMP,
      "board": {},
      "mode": "normal",
      "availableTokens": [],
    });

    return getGame(gameId);
  }

  static Future<void> removeOldGames() async {
    try {
      var query = await db
          .ref("games")
          .orderByChild("lastHeartbeat")
          .endAt(DateTime.now().subtract(const Duration(hours: 2)).toUtc().millisecondsSinceEpoch)
          .once("value");
      query.snapshot.forEach((child) => child.ref.remove());
      print("Removed ${query.snapshot.numChildren()} games");
    } catch (e) {
      print("Error on removing old games: $e");
    }
  }
}
