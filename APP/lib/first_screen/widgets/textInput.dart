import 'package:flutter/material.dart';
import 'package:say_it/Utils/widgets/circle.dart';

class UserInput extends StatelessWidget {
  const UserInput({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Container(
        height: 200,
        decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.blue),
            borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.only(top: 8.0, right: 8, left: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 248, 248, 248),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: TextField(
                    maxLines: null,
                    expands: true,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
              Row(
                children: [
                  IconButton(
                      onPressed: () {
                        _showOverlayDialog(context);
                      },
                      icon: Icon(
                        Icons.mic,
                        color: Colors.blue,
                        size: 30.0,
                      )),
                  IconButton(
                      onPressed: () {},
                      icon: Icon(
                        Icons.camera_alt_rounded,
                        color: Colors.blue,
                        size: 30.0,
                      ))
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}

void _showOverlayDialog(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black.withOpacity(0.6), // Oscurece el fondo
    builder: (context) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Padding(
            padding: const EdgeInsets.all(60.0),
            child: Container(
                width: 350,
                padding: EdgeInsets.all(8),
                constraints: BoxConstraints(maxHeight: 500),
                child: Text(
                  "Aquí se debe escribir lo que se vaya escuchando...",
                  style: TextStyle(
                    fontSize: 25,
                    color: Colors.white,
                    decoration: TextDecoration.none,
                  ),
                )),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 60.0),
            child: CircleVoice(),
          )
        ],
      );
    },
  );
}
