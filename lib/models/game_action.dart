import 'token.dart';
import 'value_subscription.dart';

class GameAction with JsonEncodable {
  String playerId;
  String action;
  bool processed = false;

  GameAction._(this.playerId, this.action, [this.processed = false]);

  GameAction.removePlacement(this.playerId) : action = "remove-placement";
  GameAction.back(this.playerId) : action = "back";
  GameAction.finish(this.playerId) : action = "finish";

  static GameAction fromMap(Map<String, dynamic> map) {
    if (map["action"] == "placement") return PlacementAction.fromMap(map);
    return GameAction._(map["playerId"] as String, map["action"] as String, map["processed"] as bool? ?? false);
  }

  @override
  dynamic toJson() => {
        "playerId": playerId,
        "action": action,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GameAction && runtimeType == other.runtimeType && playerId == other.playerId && action == other.action;

  @override
  int get hashCode => playerId.hashCode ^ action.hashCode;
}

class PlacementAction extends GameAction {
  Pos pos;
  Token token;
  bool commit;

  PlacementAction(String playerId, this.pos, this.token, this.commit, [bool processed = false])
      : super._(playerId, "placement", processed);

  static PlacementAction fromMap(Map<String, dynamic> map) {
    return PlacementAction(map["playerId"] as String, Pos(map["x"] as int, map["y"] as int),
        Token(map["token"] as String), map["commit"] as bool, map["processed"] as bool? ?? false);
  }

  @override
  Map<String, dynamic> toJson() => {
        ...super.toJson(),
        "x": pos.x,
        "y": pos.y,
        "token": token.tag,
        "commit": commit,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      super == other &&
          other is PlacementAction &&
          runtimeType == other.runtimeType &&
          pos == other.pos &&
          token == other.token &&
          commit == other.commit;

  @override
  int get hashCode => super.hashCode ^ pos.hashCode ^ token.hashCode ^ commit.hashCode;
}