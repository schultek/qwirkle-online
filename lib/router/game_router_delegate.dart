import 'package:flutter/material.dart';

import '../screens/game/game_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/loading/loading_screen.dart';
import 'game_route_path.dart';

class GameRouterDelegate extends RouterDelegate<GameRoutePath>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<GameRoutePath> {
  @override
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  GameRoutePath? currentRoute;
  static bool isLoading = true;

  GameRouterDelegate();

  @override
  Future<void> setInitialRoutePath(GameRoutePath configuration) async {
    setNewRoutePath(configuration);
  }

  @override
  Future<void> setNewRoutePath(GameRoutePath configuration) {
    return Future.sync(() {
      isLoading = false;
      currentRoute = configuration;
      notifyListeners();
    });
  }

  @override
  GameRoutePath? get currentConfiguration => currentRoute;

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: navigatorKey,
      pages: [
        if (isLoading || currentRoute == null)
          FadeAnimationPage(
            key: const ValueKey("loading"),
            child: LoadingScreen(),
          )
        else if (currentRoute!.isHome)
          FadeAnimationPage(
            key: const ValueKey("home"),
            child: HomeScreen(),
          )
        else if (currentRoute!.isGame)
          FadeAnimationPage(
            key: const ValueKey("game"),
            child: GameScreen(currentRoute!.game!),
          )
      ],
      onPopPage: (route, result) {
        return false;
      },
    );
  }
}

class FadeAnimationPage extends Page {
  final Widget child;

  const FadeAnimationPage({LocalKey? key, required this.child}) : super(key: key);

  @override
  Route createRoute(BuildContext context) {
    return PageRouteBuilder(
      settings: this,
      pageBuilder: (context, animation, animation2) {
        var curveTween = CurveTween(curve: Curves.easeIn);
        return FadeTransition(
          opacity: animation.drive(curveTween),
          child: child,
        );
      },
    );
  }
}
