import 'dart:async';

import 'package:flutter/material.dart';

class CircleVoice extends StatefulWidget {
  const CircleVoice({super.key});

  @override
  _CircleVoiceState createState() => _CircleVoiceState();
}

class _CircleVoiceState extends State<CircleVoice> {
  Timer? _timer;
  double _scale = 1;
  int alpha = 100;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(milliseconds: 15), (timer) {
      if (!mounted) return;
      setState(() {
        _scale += .01;
        alpha -= 5;
        if (_scale > 1.5) {
          _scale = 1;
          alpha = 255;
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Transform.scale(
          scale: _scale,
          child: Container(
            height: 100,
            width: 100,
            decoration: BoxDecoration(
                color: Colors.blue.withAlpha(alpha),
                borderRadius: BorderRadius.circular(100)),
          ),
        ),
        Transform.scale(
          scale: _scale - .20,
          child: Container(
            height: 100,
            width: 100,
            decoration: BoxDecoration(
                border: Border.all(color: Colors.white.withAlpha(alpha)),
                borderRadius: BorderRadius.circular(100)),
          ),
        ),
        Container(
          height: 100,
          width: 100,
          decoration: BoxDecoration(
            color: Colors.blue.withAlpha(200),
            borderRadius: BorderRadius.circular(100),
          ),
          child: Icon(
            Icons.mic,
            color: Colors.white,
            size: 50.0,
          ),
        )
      ],
    );
  }
}
