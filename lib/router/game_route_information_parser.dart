import 'package:flutter/material.dart';

import '../services/game_service.dart';
import 'game_route_path.dart';

class GameRouteInformationParser extends RouteInformationParser<GameRoutePath> {
  @override
  Future<GameRoutePath> parseRouteInformation(RouteInformation routeInformation) async {
    var uri = Uri.parse(routeInformation.location!);
    if (uri.pathSegments.length >= 2 && uri.pathSegments[0] == 'game') {
      var gameId = uri.pathSegments[1];
      return GameRoutePath.game(await GameService.getGame(gameId));
    } else if (uri.pathSegments.length >= 2 && uri.pathSegments[0] == 'join') {
      var gameId = uri.pathSegments[1];
      return GameRoutePath.game(await GameService.getGame(gameId));
    } else {
      return GameRoutePath.home();
    }
  }

  @override
  RouteInformation? restoreRouteInformation(GameRoutePath configuration) {
    return RouteInformation(location: configuration.path);
  }
}
