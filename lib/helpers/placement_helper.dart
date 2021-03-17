import '../models/game_action.dart';
import '../models/token.dart';

bool isValidPlacement(PlacementAction placement, Map<Pos, Cell> cells, List<TokenPlacement> moves) {
  if (cells[const Pos(0, 0)] is TokenPlaceholder) return true;

  var token = placement.token;
  var pos = placement.pos;
  bool? verticalSameColor, horizontalSameColor;
  bool hasRow = false, hasColumn = false;
  Set<String> line = {};

  bool isNextValid(Token next, bool sameColor) {
    if (sameColor) {
      if (line.contains(next.symbol)) return false;
      line.add(next.symbol);
      return next.color == token.color && next.symbol != token.symbol;
    } else {
      if (line.contains(next.color)) return false;
      line.add(next.color);
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

  line = {};

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
      ((sameRow || sameColumn) && !hasColumn && !hasRow && moves.any((m) => m.pos == const Pos(0, 0)));
}
