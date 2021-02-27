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
      dbSubscriptions.add(gameRef.child("actions").onChildAdded.listen((event) async {
        var action = GameAction.fromMap(event.snapshot.val() as Map<String, dynamic>);

        if (action.result != null) {
          return;
        } else if (state.value == "waiting") {
          if (action is! JoinAction) return;
        } else if (action.playerId != currentPlayer.value) {
          return;
        }

        dynamic result = true;

        if (action is JoinAction) {
          var players = (await gameRef.child("players").once("value")).snapshot.val() as Map? ?? {};
          var state = (await gameRef.child("state").once("value")).snapshot.val() as String;

          if (state == "waiting" && players.length < 6) {
            await gameRef.child("players/${action.playerId}").set({
              "nickname": action.nickname,
              "points": 0,
            });
            result = true;
          } else {
            result = false;
          }
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
        } else if (action.action == "remove-placement") {
          await currentPlacement.set(null);
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
        } else if (action.action == "replace-tokens") {
          var playerTokensRef = gameRef.child("players/${action.playerId}/tokens");

          var tokenCount = ((await playerTokensRef.once("value")).snapshot.val() as List).length;

          var newTokens = List.generate(tokenCount, (index) => Token(Token.randomTag()));

          var playerIndex = players.value.indexWhere((p) => p.id == currentPlayer.value);
          playerIndex = (playerIndex + 1) % players.value.length;

          await Future.wait([
            currentPlacement.set(null),
            currentMove.set(null),
          ]);

          await currentPlayer.set(players.value[playerIndex].id);
          await playerTokensRef.set(ValueSubscription.encode(newTokens));
        }

        await event.snapshot.ref.child("result").set(result);
      }));
    }
  }

  Future<T> requestAction<T>(GameAction action, {bool sendDuplicate = false}) async {
    if (!sendDuplicate && lastAction == action) return lastAction!.result as T;
    var ref = gameRef.child("actions").push(action.toJson());
    return (await ref.child("result").onValue.firstWhere((e) => e.snapshot.exists())).snapshot.val() as T;
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

    var sameColumn = moves.every((m) => m.pos.x == pos.x);
    var sameRow = moves.every((m) => m.pos.y == pos.y);

    return (sameRow && hasRow) || (sameColumn && hasColumn) || ((sameRow || sameColumn) && !hasColumn && !hasRow);
  }

  void dispose() {
    valueSubscriptions.values.forEach((s) => s.dispose());
    dbSubscriptions.forEach((s) => s.cancel());
  }
}
