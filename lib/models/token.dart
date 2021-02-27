import 'dart:math';

import 'package:flutter/material.dart';

import 'painters.dart';
import 'value_subscription.dart';

class Pos {
  int x, y;
  Pos(this.x, this.y);

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

class Token extends Cell with JsonEncodable {
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

  @override
  String toJson() => tag;
}

class TokenPlaceholder extends Cell {}

class TokenPlacement with JsonEncodable {
  Pos pos;
  Token token;
  bool isAllowed;
  TokenPlacement(this.pos, this.token, this.isAllowed);

  static TokenPlacement? fromMap(Map<String, dynamic>? map) {
    return map != null
        ? TokenPlacement(Pos(map["x"] as int, map["y"] as int), Token(map["token"] as String), map["isAllowed"] as bool)
        : null;
  }

  @override
  Map<String, dynamic> toJson() => {
        "x": pos.x,
        "y": pos.y,
        "token": token.tag,
        "isAllowed": isAllowed,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TokenPlacement &&
          runtimeType == other.runtimeType &&
          pos == other.pos &&
          token == other.token &&
          isAllowed == other.isAllowed;

  @override
  int get hashCode => pos.hashCode ^ token.hashCode ^ isAllowed.hashCode;
}

class PlayerMove with JsonEncodable {
  List<TokenPlacement> placements;

  PlayerMove(this.placements);

  static PlayerMove? fromList(List<dynamic>? list) {
    return list != null
        ? PlayerMove(list
            .map((d) => TokenPlacement(Pos(d["x"] as int, d["y"] as int), Token(d["token"] as String), true))
            .toList())
        : null;
  }

  @override
  List<dynamic> toJson() => placements
      .map((p) => {
            "x": p.pos.x,
            "y": p.pos.y,
            "token": p.token.tag,
          })
      .toList();

  static PlayerMove join(PlayerMove? move, TokenPlacement placement) {
    return PlayerMove([...move?.placements ?? [], placement]);
  }
}
