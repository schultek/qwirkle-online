import 'token.dart';

extension Board on Map<Pos, Cell> {
  static Map<Pos, Cell> fromMap(Map<String, dynamic>? map) {
    var board = map?.map((key, value) {
      var pos = key.split(";").map(int.parse).toList();
      return MapEntry(Pos(pos[0], pos[1]), Token(value as String));
    });
    Map<Pos, TokenPlaceholder> placeholders = {const Pos(0, 0): TokenPlaceholder()};
    board?.forEach((key, value) {
      placeholders[Pos(key.x - 1, key.y)] = TokenPlaceholder();
      placeholders[Pos(key.x + 1, key.y)] = TokenPlaceholder();
      placeholders[Pos(key.x, key.y - 1)] = TokenPlaceholder();
      placeholders[Pos(key.x, key.y + 1)] = TokenPlaceholder();
    });
    return {...placeholders, ...board ?? {}};
  }

  List<T> mapList<T>(T Function(Pos pos, Cell cell) fn) {
    return entries.map((e) => fn(e.key, e.value)).toList();
  }

  Map<String, dynamic> toJson() {
    var tokens = entries.where((e) => e.value is Token);
    return Map.fromEntries(tokens.map((e) => MapEntry("${e.key.x};${e.key.y}", (e.value as Token).tag)));
  }

  bool equals(Map<Pos, Cell> other) {
    if (length != other.length) return false;
    return other.entries.every((e) => this[e.key] == e.value) && entries.every((e) => other[e.key] == e.value);
  }
}
