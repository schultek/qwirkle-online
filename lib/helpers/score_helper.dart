// ignore: import_of_legacy_library_into_null_safe
import 'package:tuple/tuple.dart';

import '../models/token.dart';

Tuple2<double, int> calculateScore(List<TokenPlacement> placements, Map<Pos, Cell> cells) {
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
