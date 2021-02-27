import 'dart:async';

// ignore: import_of_legacy_library_into_null_safe
import 'package:firebase/firebase.dart';
// ignore: import_of_legacy_library_into_null_safe
import 'package:shortid/shortid.dart';

import '../models/game.dart';
import 'auth_service.dart';

class GameService {
  static Database get db => database();

  static final Map<String, Game> games = {};

  static Future<Game> getGame(String gameId) async {
    return games[gameId] ??= await Game.setup(gameId, await AuthService.getUserId());
  }

  static Future<Game> createGame() async {
    String gameId = shortid.generate();

    removeOldGames();

    var gameRef = db.ref("games/$gameId");

    await gameRef.set({
      "creatorUserId": await AuthService.getUserId(),
      "state": "waiting",
      "currentPlayer": null,
      "players": {},
      "lastHeartbeat": DateTime.now().toUtc().toIso8601String(),
      "board": {},
    });

    return getGame(gameId);
  }

  static Future<void> removeOldGames() async {
    var query = await db
        .ref("games")
        .orderByChild("lastHeartbeat")
        .endAt(DateTime.now().subtract(const Duration(hours: 2)).toUtc().toIso8601String())
        .once("value");
    query.snapshot.forEach((child) => child.ref.remove());
  }
}
