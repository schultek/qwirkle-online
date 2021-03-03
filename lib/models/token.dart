import 'dart:math';

import 'package:flutter/material.dart';

import 'painters.dart';

class Pos {
  final int x, y;
  const Pos(this.x, this.y);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Pos && runtimeType == other.runtimeType && x == other.x && y == other.y;

  @override
  int get hashCode => x.hashCode ^ y.hashCode;
}

class Cell {
  Key key;
  Cell() : key = UniqueKey();
}

class Token extends Cell {
  String tag;
  CustomPainter painter;

  Token(this.tag)
      : painter = SymbolPainter.fromTag(tag),
        super();

  String get color => tag[0];
  String get symbol => tag[1];

  static List<Token> fromList(List<dynamic>? data) {
    return data?.map((d) => Token(d as String)).toList() ?? [];
  }

  static String randomTag() {
    var r = ["y", "o", "r", "p", "b", "g"][Random().nextInt(6)];
    return "$r${Random().nextInt(6) + 1}";
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Token && runtimeType == other.runtimeType && tag == other.tag;

  @override
  int get hashCode => tag.hashCode;

  String toJson() => tag;
}

class TokenPlaceholder extends Cell {}

class TokenPlacement {
  Pos pos;
  Token token;
  TokenPlacement(this.pos, this.token);

  static TokenPlacement? fromMap(Map<String, dynamic>? map) {
    return map != null ? TokenPlacement(Pos(map["x"] as int, map["y"] as int), Token(map["token"] as String)) : null;
  }

  Map<String, dynamic> toJson() => {
        "x": pos.x,
        "y": pos.y,
        "token": token.tag,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TokenPlacement && runtimeType == other.runtimeType && pos == other.pos && token == other.token;

  @override
  int get hashCode => pos.hashCode ^ token.hashCode;
}

extension PlayerMove on List<TokenPlacement> {
  static List<TokenPlacement> fromList(List<dynamic>? list) {
    return (list ?? [])
        .map((d) => TokenPlacement(Pos(d["x"] as int, d["y"] as int), Token(d["token"] as String)))
        .toList();
  }

  List<dynamic> toJson() => map((p) => {
        "x": p.pos.x,
        "y": p.pos.y,
        "token": p.token.tag,
      }).toList();
}
