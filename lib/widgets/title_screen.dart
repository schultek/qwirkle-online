import 'package:flutter/material.dart';

class TitleScreen extends StatelessWidget {
  final Widget child;
  const TitleScreen(this.child);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade900,
      body: Center(
        child: IntrinsicWidth(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _qwirkleTitle(),
              const SizedBox(height: 50),
              child,
            ],
          ),
        ),
      ),
    );
  }

  Widget _qwirkleTitle() {
    return RichText(
      text: const TextSpan(
          text: "",
          style: TextStyle(
            fontSize: 80,
            fontWeight: FontWeight.bold,
          ),
          children: [
            TextSpan(text: "Q", style: TextStyle(color: Colors.red)),
            TextSpan(text: "W", style: TextStyle(color: Colors.blue)),
            TextSpan(text: "I", style: TextStyle(color: Colors.yellow)),
            TextSpan(text: "R", style: TextStyle(color: Colors.purple)),
            TextSpan(text: "K", style: TextStyle(color: Colors.green)),
            TextSpan(text: "L", style: TextStyle(color: Colors.blue)),
            TextSpan(text: "E", style: TextStyle(color: Colors.orange)),
          ]),
      textAlign: TextAlign.center,
    );
  }
}
