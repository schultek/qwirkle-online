import 'token.dart';
import 'value_subscription.dart';

class Board with JsonEncodable {
  Map<Pos, Cell> board = {};
  Board(this.board);

  static Board fromMap(Map<String, dynamic>? map) {
    var board = map?.map((key, value) {
      var pos = key.split(";").map(int.parse).toList();
      return MapEntry(Pos(pos[0], pos[1]), Token(value as String));
    });
    Map<Pos, TokenPlaceholder> placeholders = {Pos(0, 0): TokenPlaceholder()};
    board?.forEach((key, value) {
      placeholders[Pos(key.x - 1, key.y)] = TokenPlaceholder();
      placeholders[Pos(key.x + 1, key.y)] = TokenPlaceholder();
      placeholders[Pos(key.x, key.y - 1)] = TokenPlaceholder();
      placeholders[Pos(key.x, key.y + 1)] = TokenPlaceholder();
    });
    return Board({...placeholders, ...board ?? {}});
  }

  List<T> map<T>(T Function(Pos pos, Cell cell) fn) {
    return board.entries.map((e) => fn(e.key, e.value)).toList();
  }

  @override
  Map<String, dynamic> toJson() {
    var tokens = board.entries.where((e) => e.value is Token);
    return Map.fromEntries(tokens.map((e) => MapEntry("${e.key.x};${e.key.y}", (e.value as Token).tag)));
  }
}
