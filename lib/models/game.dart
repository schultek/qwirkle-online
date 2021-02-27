import 'dart:async';
import 'dart:math';

// ignore: import_of_legacy_library_into_null_safe
import 'package:firebase/firebase.dart';
import 'package:tuple/tuple.dart';

import 'board.dart';
import 'game_action.dart';
import 'token.dart';
import 'value_subscription.dart';

class Player {
  String id;
  String nickname;
  int tokenCount;
  List<Token> tokens;
  String color;
  double points;

  Player(this.id, this.nickname, this.tokenCount, this.tokens, this.points, this.color);

  static List<Player> fromIdMap(Map<String, dynamic>? playerMap) {
    return playerMap?.entries.map((entry) {
          return Player(
            entry.key,
            entry.value["nickname"] as String,
            (entry.value["tokenCount"] as num).round(),
            Token.fromList(entry.value["tokens"] as List),
            entry.value["points"] as double,
            entry.value["color"] as String,
          );
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

  Function(dynamic v) get encode => ValueSubscription.encode;

  ValueSubscription<String> get state => subscribedValue("state", "");
  ValueSubscription<List<Player>> get players => subscribedValue("players", [], Player.fromIdMap);
  ValueSubscription<Board> get board => subscribedValue("board", Board({}), Board.fromMap);

  ValueSubscription<String?> get currentPlayer => subscribedValue("currentPlayer", null);
  ValueSubscription<TokenPlacement?> get currentPlacement =>
      subscribedValue("currentPlacement", null, TokenPlacement.fromMap);
  ValueSubscription<PlayerMove?> get currentMove => subscribedValue("currentMove", null, PlayerMove.fromList);

  ValueSubscription<List<Token>> get tokens => subscribedValue("players/$playerId/tokens", <Token>[], Token.fromList);

  late Stream<Tuple2<String, String>> messages;

  static Future<Game> setup(String id, String playerId) async {
    var game = Game._(id, playerId);
    await game._setup();
    return game;
  }

  GameAction? lastAction;

  List<StreamSubscription> dbSubscriptions = [];

  Future<void> _setup() async {
    messages = gameRef.child("messages").onChildAdded.map((e) => Tuple2(e.snapshot.key, e.snapshot.val() as String));

    var creatorUserId = (await gameRef.child("creatorUserId").once("value")).snapshot.val();

    dbSubscriptions.add(gameRef.child("actions").onChildAdded.listen((event) {
      lastAction = GameAction.fromMap(event.snapshot.val() as Map<String, dynamic>);
    }));

    isGameMaster = creatorUserId == playerId;
    if (isGameMaster) {
      state;
      currentPlayer;
      players;
      currentMove;
      board;

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
          if (state.value == "waiting" && players.value.length < 6) {
            await gameRef.child("players/${action.playerId}").set({
              "nickname": action.nickname,
              "points": 0,
              "tokenCount": 5,
              "color": Token.randomTag()[0],
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
              playerTokensRef.set(encode([...playerTokens]..remove(action.token))),
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

            var player = players.value.firstWhere((p) => p.id == action.playerId);

            await currentPlacement.set(null);
            await board.set(Board({...board.value.board}..remove(last.pos)));
            await gameRef.child("players/${action.playerId}/tokens").set(encode([...player.tokens, last.token]));
            await currentMove.set(PlayerMove(placements));
          }
        } else if (action.action == "finish") {
          if (currentMove.value?.placements.isNotEmpty ?? false) {
            var player = players.value.firstWhere((p) => p.id == action.playerId);

            Tuple2<double, int> score = calculateScore();

            var tokens = [...player.tokens];
            var newTokenCount = player.tokenCount - score.item2;

            while (tokens.length < newTokenCount) {
              tokens.add(Token(Token.randomTag()));
            }

            var playerIndex = players.value.indexWhere((p) => p.id == currentPlayer.value);
            playerIndex = (playerIndex + 1) % players.value.length;

            gameRef.child("messages").push("+${score.item1} Punkte für ${player.nickname}");

            if (newTokenCount == 0) {
              gameRef.child("messages").push("${player.nickname} gewinnt!");
            }

            await Future.wait([
              currentPlacement.set(null),
              currentMove.set(null),
            ]);

            await currentPlayer.set(players.value[playerIndex].id);
            await gameRef.child("players/${action.playerId}/tokens").set(encode(tokens));
            await gameRef.child("players/${action.playerId}/points").set(player.points + score.item1);
            await gameRef.child("players/${action.playerId}/tokenCount").set(newTokenCount);
          } else {
            result = false;
          }
        } else if (action.action == "replace-tokens") {
          var player = players.value.firstWhere((p) => p.id == action.playerId);
          var newTokens = List.generate(player.tokenCount, (index) => Token(Token.randomTag()));

          var playerIndex = players.value.indexWhere((p) => p.id == currentPlayer.value);
          playerIndex = (playerIndex + 1) % players.value.length;

          await Future.wait([
            currentPlacement.set(null),
            currentMove.set(null),
          ]);

          await currentPlayer.set(players.value[playerIndex].id);
          await gameRef.child("players/${action.playerId}/tokens").set(encode(newTokens));
        }

        await event.snapshot.ref.child("result").set(result);
      }));
    }
  }

  Tuple2<double, int> calculateScore() {
    var placements = currentMove.value!.placements;
    var cells = board.value.board;

    Map<int, int> rows = {}, columns = {};

    for (var p in placements) {
      var pos = p.pos;

      if (!rows.containsKey(pos.y)) {
        rows[pos.y] = 1;

        while (true) {
          pos = Pos(pos.x - 1, pos.y);
          var left = cells[pos];
          if (left == null || left is! Token) break;
          rows[pos.y] = rows[pos.y]! + 1;
        }

        pos = p.pos;

        while (true) {
          pos = Pos(pos.x + 1, pos.y);
          var right = cells[pos];
          if (right == null || right is! Token) break;
          rows[pos.y] = rows[pos.y]! + 1;
        }
      }

      pos = p.pos;
      if (!columns.containsKey(pos.x)) {
        columns[pos.x] = 1;

        while (true) {
          pos = Pos(pos.x, pos.y - 1);
          var above = cells[pos];
          if (above == null || above is! Token) break;
          columns[pos.x] = columns[pos.x]! + 1;
        }

        pos = p.pos;

        while (true) {
          pos = Pos(pos.x, pos.y + 1);
          var below = cells[pos];
          if (below == null || below is! Token) break;
          columns[pos.x] = columns[pos.x]! + 1;
        }
      }
    }

    double points = 0;
    int lines = 0;

    for (var row in rows.values) {
      if (row < 2) continue;
      points += row;
      if (row == 6) {
        points += 6;
        lines++;
      }
    }

    for (var column in columns.values) {
      if (column < 2) continue;
      points += column;
      if (column == 6) {
        points += 6;
        lines++;
      }
    }

    if (rows.length == 1 && rows.values.first == 1 && columns.length == 1 && columns.values.first == 1) {
      points++;
    }

    return Tuple2(points, lines);
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

    return (sameRow && hasRow) ||
        (sameColumn && hasColumn) ||
        ((sameRow || sameColumn) && !hasColumn && !hasRow && moves.any((m) => m.pos == Pos(0, 0)));
  }

  void dispose() {
    valueSubscriptions.values.forEach((s) => s.dispose());
    valueSubscriptions = {};
    dbSubscriptions.forEach((s) => s.cancel());
    dbSubscriptions = [];
  }
}
