import 'dart:async';
import 'dart:math';

// ignore: import_of_legacy_library_into_null_safe
import 'package:firebase/firebase.dart';

import 'board.dart';
import 'game_action.dart';
import 'token.dart';
import 'value_subscription.dart';

class Player {
  String id;
  String nickname;
  List<Token> tokens;

  Player(this.id, this.nickname, this.tokens);

  static List<Player> fromIdMap(Map<String, dynamic>? playerMap) {
    return playerMap?.entries.map((entry) {
          return Player(entry.key, entry.value["nickname"] as String, Token.fromList(entry.value["tokens"] as List));
        }).toList() ??
        [];
  }
}

class Game {
  String id;
  String playerId;

  DatabaseReference gameRef;

  Game._(this.id, this.playerId) : gameRef = database().ref("games/$id");

  Map<String, ValueSubscription> valueSubscriptions = {};

  bool isGameMaster = false;

  ValueSubscription<T> subscribedValue<T, U>(String path, T initialValue, [T? Function(U? data)? mapper]) {
    if (valueSubscriptions[path] == null) {
      valueSubscriptions[path] =
          ValueSubscription<T>(gameRef.child(path), (data) => mapper?.call(data as U?) ?? data as T?, initialValue);
    }
    return valueSubscriptions[path] as ValueSubscription<T>;
  }

  ValueSubscription<String> get state => subscribedValue("state", "");
  ValueSubscription<List<Player>> get players => subscribedValue("players", [], Player.fromIdMap);
  ValueSubscription<Board> get board => subscribedValue("board", Board({}), Board.fromMap);

  ValueSubscription<String?> get currentPlayer => subscribedValue("currentPlayer", null);
  ValueSubscription<TokenPlacement?> get currentPlacement =>
      subscribedValue("currentPlacement", null, TokenPlacement.fromMap);
  ValueSubscription<PlayerMove?> get currentMove => subscribedValue("currentMove", null, PlayerMove.fromList);

  ValueSubscription<List<Token>> get tokens => subscribedValue("players/$playerId/tokens", <Token>[], Token.fromList);

  static Future<Game> setup(String id, String playerId) async {
    var game = Game._(id, playerId);
    await game._setup();
    return game;
  }

  GameAction? lastAction;

  List<StreamSubscription> dbSubscriptions = [];

  Future<void> _setup() async {
    var creatorUserId = (await gameRef.child("creatorUserId").once("value")).snapshot.val();

    dbSubscriptions.add(gameRef.child("actions").onChildAdded.listen((event) {
      lastAction = GameAction.fromMap(event.snapshot.val() as Map<String, dynamic>);
    }));

    isGameMaster = creatorUserId == playerId;
    if (isGameMaster) {
      dbSubscriptions.add(gameRef.child("join").onChildAdded.listen((event) async {
        var allowed = event.snapshot.val()["allowed"];
        if (allowed != null) return;

        var players = (await gameRef.child("players").once("value")).snapshot.val() as Map? ?? {};
        var state = (await gameRef.child("state").once("value")).snapshot.val() as String;

        if (state == "waiting" && players.length < 6) {
          var userId = event.snapshot.key;
          var nickname = event.snapshot.val()["nickname"];

          await gameRef.child("players/$userId").set({
            "nickname": nickname,
            "points": 0,
          });

          await event.snapshot.ref.child("allowed").set(true);
        } else {
          await event.snapshot.ref.child("allowed").set(false);
        }
      }));

      dbSubscriptions.add(gameRef.child("actions").onChildAdded.listen((event) async {
        var action = GameAction.fromMap(event.snapshot.val() as Map<String, dynamic>);

        if (action.playerId != currentPlayer.value || action.processed) {
          return;
        }

        if (action.action == "remove-placement") {
          await currentPlacement.set(null);
        } else if (action is PlacementAction) {
          var allowed = isValidPlacement(action);

          if (allowed && action.commit) {
            var playerTokensRef = gameRef.child("players/${action.playerId}/tokens");
            var playerTokens = Token.fromList((await playerTokensRef.once("value")).snapshot.val() as List);

            await Future.wait([
              board.set(Board({...board.value.board, action.pos: action.token})),
              currentMove.set(PlayerMove.join(currentMove.value, TokenPlacement(action.pos, action.token, true))),
              playerTokensRef.set(ValueSubscription.encode([...playerTokens]..remove(action.token))),
              currentPlacement.set(null),
            ]);
          } else {
            await currentPlacement.set(TokenPlacement(action.pos, action.token, allowed));
          }
        } else if (action.action == "back") {
          var placements = <TokenPlacement>[...currentMove.value?.placements ?? []];

          if (placements.isNotEmpty) {
            var last = placements.removeLast();

            var playerTokensRef = gameRef.child("players/${action.playerId}/tokens");
            var playerTokens = Token.fromList((await playerTokensRef.once("value")).snapshot.val() as List);

            await currentPlacement.set(null);
            await board.set(Board({...board.value.board}..remove(last.pos)));
            await playerTokensRef.set(ValueSubscription.encode([...playerTokens, last.token]));
            await currentMove.set(PlayerMove(placements));
          }
        } else if (action.action == "finish") {
          var playerTokensRef = gameRef.child("players/${action.playerId}/tokens");

          var playerTokens = Token.fromList((await playerTokensRef.once("value")).snapshot.val() as List);

          while (playerTokens.length < 5) {
            playerTokens.add(Token(Token.randomTag()));
          }

          var playerIndex = players.value.indexWhere((p) => p.id == currentPlayer.value);
          playerIndex = (playerIndex + 1) % players.value.length;

          await Future.wait([
            currentPlacement.set(null),
            currentMove.set(null),
          ]);

          await currentPlayer.set(players.value[playerIndex].id);
          await playerTokensRef.set(ValueSubscription.encode(playerTokens));
        }

        await event.snapshot.ref.child("processed").set(true);
      }));
    }
  }

  Future<void> requestAction(GameAction action, {bool sendDuplicate = false}) async {
    if (!sendDuplicate && lastAction == action) return;
    var ref = gameRef.child("actions").push(action.toJson());
    await ref.child("processed").onValue.first;
  }

  Future<bool?> canJoin() async {
    var joinRef = await gameRef.child("join/$playerId").once("value");

    if (joinRef.snapshot.exists()) {
      return joinRef.snapshot.val()["allowed"] as bool? ?? false;
    } else {
      return null;
    }
  }

  Future<bool> join(String nickname) async {
    var joinAllowed = await canJoin();
    if (joinAllowed != null) {
      return joinAllowed;
    }

    await gameRef.child("join/$playerId").set({
      "nickname": nickname,
      "allowed": null,
    });

    var allowedEntry = await gameRef.child("join/$playerId/allowed").onValue.firstWhere((event) {
      return event.snapshot.exists();
    });

    return allowedEntry.snapshot.val() as bool;
  }

  Future<void> startGame() async {
    if (!isGameMaster) return;

    for (var player in players.value) {
      await gameRef.child("players/${player.id}/tokens").set(List.generate(5, (index) => Token.randomTag()));
    }

    var randomPlayerId = players.value[Random().nextInt(players.value.length)].id;
    await currentPlayer.set(randomPlayerId);
    await state.set("running");
  }

  bool isValidPlacement(PlacementAction placement) {
    var cells = board.value.board;

    if (cells[Pos(0, 0)] is TokenPlaceholder) return true;

    var token = placement.token;
    var pos = placement.pos;
    bool? verticalSameColor, horizontalSameColor;
    bool hasRow = false, hasColumn = false;

    var moves = currentMove.value?.placements ?? [];

    bool isNextValid(Token next, bool sameColor) {
      if (sameColor) {
        return next.color == token.color && next.symbol != token.symbol;
      } else {
        return next.color != token.color && next.symbol == token.symbol;
      }
    }

    while (true) {
      pos = Pos(pos.x, pos.y - 1);
      var above = cells[pos];
      if (above == null || above is! Token) break;
      verticalSameColor ??= above.color == token.color;
      if (!isNextValid(above, verticalSameColor)) {
        return false;
      }
      if (moves.every((m) => m.pos != pos)) {
        hasColumn = true;
      }
    }

    pos = placement.pos;

    while (true) {
      pos = Pos(pos.x, pos.y + 1);
      var below = cells[pos];
      if (below == null || below is! Token) break;
      verticalSameColor ??= below.color == token.color;
      if (!isNextValid(below, verticalSameColor)) {
        return false;
      }
      if (moves.every((m) => m.pos != pos)) {
        hasColumn = true;
      }
    }

    pos = placement.pos;

    while (true) {
      pos = Pos(pos.x - 1, pos.y);
      var left = cells[pos];
      if (left == null || left is! Token) break;
      horizontalSameColor ??= left.color == token.color;
      if (!isNextValid(left, horizontalSameColor)) {
        return false;
      }
      if (moves.every((m) => m.pos != pos)) {
        hasRow = true;
      }
    }

    pos = placement.pos;

    while (true) {
      pos = Pos(pos.x + 1, pos.y);
      var right = cells[pos];
      if (right == null || right is! Token) break;
      horizontalSameColor ??= right.color == token.color;
      if (!isNextValid(right, horizontalSameColor)) {
        return false;
      }
      if (moves.every((m) => m.pos != pos)) {
        hasRow = true;
      }
    }

    pos = placement.pos;

    var sameColumn = moves.every((m) => m.pos.x == pos.x) && hasColumn;
    var sameRow = moves.every((m) => m.pos.y == pos.y) && hasRow;

    return sameRow || sameColumn;
  }

  void dispose() {
    valueSubscriptions.values.forEach((s) => s.dispose());
    dbSubscriptions.forEach((s) => s.cancel());
  }
}
