import '../models/game.dart';

class GameRoutePath {
  final String path;
  final Game? game;

  GameRoutePath.home()
      : path = "",
        game = null;
  GameRoutePath.game(Game game)
      : path = "game/${game.id}",
        game = game;
  GameRoutePath.join(Game game)
      : path = "join/${game.id}",
        game = game;

  bool get isHome => path == "";
  bool get isGame => path.startsWith("game/");
  bool get isJoin => path.startsWith("join/");

  String? get gameId => game?.id;
}
