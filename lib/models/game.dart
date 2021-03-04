import 'dart:async';
import 'dart:math';

// ignore: import_of_legacy_library_into_null_safe
import 'package:firebase/firebase.dart';
import 'package:flutter/cupertino.dart';
// ignore: import_of_legacy_library_into_null_safe
import 'package:tuple/tuple.dart';

import '../helpers/placement_helper.dart';
import '../helpers/score_helper.dart';
import 'board.dart';
import 'game_action.dart';
import 'token.dart';

extension NullableWhere<T> on Iterable<T> {
  T? get firstOrNull => isNotEmpty ? first : null;
}

extension PlayerTokens on List<Token> {
  List<String> toJson() => map((t) => t.toJson()).toList();
}

class Player {
  String id;
  String nickname;
  int tokenCount;
  List<Token> tokens;
  String color;
  double points;

  Player(this.id, this.nickname, this.tokenCount, this.tokens, this.points, this.color);

  static Map<String, Player> fromIdMap(Map<String, dynamic>? playerMap) {
    return (playerMap ?? {}).map((key, value) => MapEntry(
        key,
        Player(
          key,
          value["nickname"] as String,
          (value["tokenCount"] as num).round(),
          Token.fromList(value["tokens"] as List),
          value["points"] as double,
          value["color"] as String,
        )));
  }
}

class Game with ChangeNotifier {
  static const int InitialTokenCount = 5;

  String id;
  String playerId;

  DatabaseReference gameRef;

  Game._(this.id, this.playerId) : gameRef = database().ref("games/$id");

  bool isGameMaster = false;

  String state = "waiting";
  Map<String, Player> players = {};
  Map<Pos, Cell> board = {};

  String? currentPlayerId, winningPlayerId;
  TokenPlacement? currentPlacement;
  List<TokenPlacement> currentMove = [];

  Player get myPlayer => players[playerId]!;
  Player? get currentPlayer => players[currentPlayerId];

  late Stream<Tuple2<String, String>> messages;

  static Future<Game> setup(String id, String playerId) async {
    var game = Game._(id, playerId);
    await game._setup();
    return game;
  }

  List<StreamSubscription> dbSubscriptions = [];

  Future<void> _setup() async {
    messages = gameRef.child("messages").onChildAdded.map((e) => Tuple2(e.snapshot.key, e.snapshot.val() as String));

    gameRef.child("state").onValue.listen((e) {
      state = e.snapshot.val() as String;
      notifyListeners();
    });

    gameRef.child("players").onValue.listen((e) {
      players = Player.fromIdMap(e.snapshot.val() as Map<String, dynamic>);
      notifyListeners();
    });

    gameRef.child("board").onValue.listen((e) {
      board = Board.fromMap(e.snapshot.val() as Map<String, dynamic>);
      notifyListeners();
    });

    gameRef.child("currentPlayerId").onValue.listen((e) {
      currentPlayerId = e.snapshot.val() as String?;
      notifyListeners();
    });

    gameRef.child("currentPlacement").onValue.listen((e) {
      currentPlacement = TokenPlacement.fromMap(e.snapshot.val() as Map<String, dynamic>?);
      notifyListeners();
    });

    gameRef.child("currentMove").onValue.listen((e) {
      currentMove = PlayerMove.fromList(e.snapshot.val() as List<dynamic>?);
      notifyListeners();
    });

    gameRef.child("winningPlayerId").onValue.listen((e) {
      winningPlayerId = e.snapshot.val() as String?;
      notifyListeners();
    });

    var creatorUserId = (await gameRef.child("creatorUserId").once("value")).snapshot.val();

    // dbSubscriptions.add(gameRef.child("actions").onChildAdded.listen((event) {
    //   lastAction = GameAction.fromMap(event.snapshot.val() as Map<String, dynamic>);
    // }));

    isGameMaster = creatorUserId == playerId;
    if (isGameMaster) {
      dbSubscriptions.add(gameRef.child("actions").onChildAdded.listen((event) async {
        var action = GameAction.fromMap(event.snapshot.val() as Map<String, dynamic>);

        if (action.result != null) {
          return;
        } else if (state == "waiting") {
          if (action is! JoinAction) return;
        } else if (action.playerId != currentPlayerId) {
          return;
        }

        dynamic result = true;

        if (action is JoinAction) {
          if (state == "waiting" && players.length < 6) {
            await gameRef.child("players/${action.playerId}").set({
              "nickname": action.nickname,
              "points": 0,
              "tokenCount": InitialTokenCount,
              "color": Token.randomTag()[0],
            });
            result = true;
          } else {
            result = false;
          }
        } else if (action is PlacementAction) {
          var allowed = isValidPlacement(action, board, currentMove);

          if (allowed && action.commit) {
            var player = players[action.playerId]!;

            await Future.wait([
              gameRef.child("board").set({...board, action.pos: action.token}.toJson()),
              gameRef.child("currentMove").set([...currentMove, TokenPlacement(action.pos, action.token)].toJson()),
              gameRef
                  .child("players/${action.playerId}/tokens")
                  .set(([...player.tokens]..remove(action.token)).toJson()),
              gameRef.child("currentPlacement").set(null),
            ]);
          } else {
            await gameRef.child("currentPlacement").set(TokenPlacement(action.pos, action.token).toJson());
          }

          result = allowed;
        } else if (action.action == "remove-placement") {
          await gameRef.child("currentPlacement").set(null);
        } else if (action.action == "back") {
          var placements = [...currentMove];

          if (placements.isNotEmpty) {
            var last = placements.removeLast();

            var player = players[action.playerId]!;

            await gameRef.child("currentPlacement").set(null);
            await gameRef.child("board").set(({...board}..remove(last.pos)).toJson());
            await gameRef.child("players/${action.playerId}/tokens").set([...player.tokens, last.token].toJson());
            await gameRef.child("currentMove").set(placements.toJson());
          }
        } else if (action.action == "finish") {
          if (currentMove.isNotEmpty) {
            var player = players[action.playerId]!;

            Tuple2<double, int> score = calculateScore(currentMove, board);

            var tokens = [...player.tokens];
            var newTokenCount = max(0, player.tokenCount - score.item2);

            while (tokens.length < newTokenCount) {
              tokens.add(Token(Token.randomTag()));
            }

            var playerIds = players.keys.toList()..sort();
            var playerIndex = playerIds.indexOf(currentPlayerId!);
            var nextPlayerIndex = (playerIndex + 1) % playerIds.length;
            var nextPlayerId = playerIds[nextPlayerIndex];

            gameRef.child("messages").push("+${score.item1} Punkte für ${player.nickname}");

            if (newTokenCount == 0) {
              gameRef.child("messages").push("${player.nickname} gewinnt!");
              gameRef.child("state").set("finished");
              gameRef.child("winningPlayerId").set(player.id);
            }

            await Future.wait([
              gameRef.child("currentPlacement").set(null),
              gameRef.child("currentMove").set(null),
            ]);

            await gameRef.child("currentPlayerId").set(nextPlayerId);
            await gameRef.child("players/${action.playerId}/tokens").set(tokens.toJson());
            await gameRef.child("players/${action.playerId}/points").set(player.points + score.item1);
            await gameRef.child("players/${action.playerId}/tokenCount").set(newTokenCount);
          } else {
            result = false;
          }
        } else if (action.action == "replace-tokens") {
          var player = players[action.playerId]!;
          var newTokens = List.generate(player.tokenCount, (index) => Token(Token.randomTag()));

          var playerIds = players.keys.toList()..sort();
          var playerIndex = playerIds.indexOf(currentPlayerId!);
          var nextPlayerIndex = (playerIndex + 1) % playerIds.length;
          var nextPlayerId = playerIds[nextPlayerIndex];

          await Future.wait([
            gameRef.child("currentPlacement").set(null),
            gameRef.child("currentMove").set(null),
          ]);

          await gameRef.child("currentPlayerId").set(nextPlayerId);
          await gameRef.child("players/${action.playerId}/tokens").set(newTokens.toJson());
        }

        await event.snapshot.ref.child("result").set(result);
      }));
    }
  }

  GameAction? lastRequestedAction;
  Future<dynamic>? actionResult;

  Future<T> requestAction<T>(GameAction action, {bool sendDuplicate = false}) async {
    if (!sendDuplicate && lastRequestedAction == action) {
      return await actionResult! as T;
    }
    lastRequestedAction = action;
    var ref = gameRef.child("actions").push(action.toJson());
    actionResult =
        ref.child("result").onValue.firstWhere((e) => e.snapshot.exists()).then((e) => e.snapshot.val() as T);
    return await actionResult as T;
  }

  Future<bool> hasJoined() async {
    var playerRef = await gameRef.child("players/$playerId").once("value");

    if (playerRef.snapshot.exists()) {
      return true;
    } else {
      return false;
    }
  }

  Future<void> startGame() async {
    if (!isGameMaster) return;

    for (var id in players.keys) {
      await gameRef.child("players/$id/tokens").set(List.generate(InitialTokenCount, (index) => Token.randomTag()));
    }

    var randomPlayerId = players.keys.toList()[Random().nextInt(players.length)];
    await gameRef.child("currentPlayerId").set(randomPlayerId);
    await gameRef.child("state").set("running");
  }

  @override
  void dispose() {
    super.dispose();
    dbSubscriptions.forEach((s) => s.cancel());
    dbSubscriptions = [];
  }
}
