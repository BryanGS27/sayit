import 'package:flutter/material.dart';

class AppBarSayIt extends StatelessWidget {
  const AppBarSayIt({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          color: Colors.lightBlue,
          borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20))),
      constraints: BoxConstraints(minHeight: 80),
      child: Center(
          heightFactor: 80,
          child: Text(
            "Say It - Traductor",
            style: TextStyle(
                fontSize: 30,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.bold,
                color: Colors.white),
          )),
    );
  }
}
