// ignore: import_of_legacy_library_into_null_safe
import 'package:firebase/firebase.dart';
import 'package:flutter/material.dart';
import 'package:url_strategy/url_strategy.dart';

import 'router/game_route_information_parser.dart';
import 'router/game_route_path.dart';
import 'router/game_router_delegate.dart';

void main() {
  setPathUrlStrategy();
  runApp(QwirkleApp());
}

class QwirkleApp extends StatefulWidget {
  @override
  _QwirkleAppState createState() => _QwirkleAppState();

  static _QwirkleAppState of(BuildContext context) {
    return context.findAncestorStateOfType()!;
  }
}

class _QwirkleAppState extends State<QwirkleApp> {
  late final GameRouterDelegate _routerDelegate;
  late final GameRouteInformationParser _routeInformationParser;

  @override
  void initState() {
    super.initState();

    _routerDelegate = GameRouterDelegate();
    _routeInformationParser = GameRouteInformationParser();

    if (apps.isEmpty) {
      initializeApp(
        apiKey: "AIzaSyCspVjUoLJaSQjhNJ2ZFsb5_O-oLt8Ktis",
        authDomain: "qwirkle-game-online.firebaseapp.com",
        projectId: "qwirkle-game-online",
        storageBucket: "qwirkle-game-online.appspot.com",
        databaseURL: "https://qwirkle-game-online-default-rtdb.europe-west1.firebasedatabase.app/",
      );
    }
  }

  void open(GameRoutePath path) {
    _routerDelegate.setNewRoutePath(path);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Qwirkle Online',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(),
      routerDelegate: _routerDelegate,
      routeInformationParser: _routeInformationParser,
    );
  }
}
