import 'package:flutter/material.dart';

class MyWidget extends StatefulWidget {
  final Widget child;
  const MyWidget({super.key, required this.child});

  @override
  _MyWidgetState createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        barrierColor: Colors.black.withOpacity(0.6),
        builder: (context) {
          return Dialog(
            backgroundColor: Colors.transparent,
            child: widget.child,
          );
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(); // No necesita dibujar nada en el widget original
  }
}
