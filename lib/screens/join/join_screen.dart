import 'package:flutter/material.dart';

import '../../main.dart';
import '../../models/game.dart';
import '../../router/game_route_path.dart';
import '../../widgets/title_screen.dart';

class JoinScreen extends StatefulWidget {
  final Game game;
  const JoinScreen(this.game);

  @override
  _JoinScreenState createState() => _JoinScreenState();
}

class _JoinScreenState extends State<JoinScreen> {
  String? _nickname;

  @override
  void initState() {
    super.initState();

    widget.game.canJoin().then((canJoin) {
      if (canJoin == true) {
        QwirkleApp.of(context).open(GameRoutePath.game(widget.game));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return TitleScreen(
      Column(
        children: [
          TextField(
            decoration: InputDecoration(
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              hintText: "Nickname",
              hintStyle: const TextStyle(color: Colors.white),
            ),
            style: const TextStyle(color: Colors.white),
            onChanged: (text) {
              _nickname = text;
            },
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () async {
              if (_nickname == null) return;

              bool allowJoin = await widget.game.join(_nickname!);
              if (allowJoin) {
                QwirkleApp.of(context).open(GameRoutePath.game(widget.game));
              } else {
                print("NOT ALLOWED");
              }
            },
            style: ButtonStyle(
              backgroundColor: MaterialStateProperty.all(Colors.black),
              padding: MaterialStateProperty.all(const EdgeInsets.all(20)),
            ),
            child: const Text(
              "Beitreten",
              style: TextStyle(color: Colors.white),
            ),
          )
        ],
      ),
    );
  }
}
