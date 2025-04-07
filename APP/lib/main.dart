import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:say_it/Utils/widgets/circle.dart';
import 'package:say_it/first_screen/widgets/camera.dart';
import 'package:say_it/widgets/appBar.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primaryColor: Colors.amber,
        primarySwatch: Colors.red,
        useMaterial3: false,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.green, // Color de fondo
          elevation: 1, // Sombra
          titleTextStyle: TextStyle(
            color: Colors.black, // Color del texto
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: IconThemeData(color: Colors.amber), // Color de íconos
        ),
      ),
      home: const MyHomePage(title: 'Say It - Traductor'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController _controller = TextEditingController();
  List<VideoPlayerController> controllers = [];
  List<VideoInfo> videos = [];
  int currentVideoIndex = 0;

  @override
  void initState() {
    super.initState();
    setState(() {});
  }

  @override
  void dispose() {
    for (final controller in controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(80),
        child: AppBarSayIt(),
      ),
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 30, bottom: 10),
            ),
            Padding(
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
                            controller: _controller,
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
                              onPressed: () async {
                                setState(() {
                                  videos = [];
                                  controllers = [];
                                });
                                videos = await obtenerVideosDesdeTexto(
                                    _controller.text);
                                for (final video in videos) {
                                  final file = await video.getVideoFile();
                                  final controller =
                                      VideoPlayerController.file(file);
                                  await controller.initialize();
                                  controllers.add(controller);
                                }
                                setState(() {});
                              },
                              icon: Icon(
                                Icons.send_rounded,
                                color: Colors.blue,
                                size: 30.0,
                              )),
                          IconButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => CameraScreen()),
                                );
                              },
                              icon: Icon(
                                Icons.camera_alt_rounded,
                                color: Colors.blue,
                                size: 30.0,
                              )),
                          IconButton(
                              onPressed: () {
                                _showOverlayDialog(context);
                              },
                              icon: Icon(
                                CupertinoIcons.speaker_3_fill,
                                color: Colors.blue,
                                size: 30.0,
                              )),
                          IconButton(
                              onPressed: () {
                                _showOverlayDialog(context);
                              },
                              icon: Icon(
                                Icons.mic,
                                color: Colors.blue,
                                size: 30.0,
                              )),
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 30),
              child: Container(
                height: 400,
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
                          width: double.infinity,
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 248, 248, 248),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: controllers.isEmpty
                              ? Center(child: CircularProgressIndicator())
                              : ListView.builder(
                                  itemCount: controllers.length,
                                  itemBuilder: (context, index) {
                                    final controller = controllers[index];
                                    return Column(
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Text(
                                            videos[index].nombre.toUpperCase(),
                                            style: TextStyle(
                                                fontSize: 25,
                                                fontWeight: FontWeight.bold,
                                                fontStyle: FontStyle.italic),
                                          ),
                                        ),
                                        AspectRatio(
                                          aspectRatio:
                                              controller.value.aspectRatio,
                                          child: VideoPlayer(controller),
                                        ),
                                        IconButton(
                                          icon: Icon(controller.value.isPlaying
                                              ? Icons.pause
                                              : Icons.play_arrow),
                                          onPressed: () {
                                            setState(() {
                                              controller.value.isPlaying
                                                  ? controller.pause()
                                                  : controller.play();
                                            });
                                          },
                                        ),
                                        Divider()
                                      ],
                                    );
                                  },
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
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
                  "Aquí se debe escribir la traducción mientras se reproduce lo que se tradujo.",
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

class VideoInfo {
  final String nombre;
  final String videoBase64;

  VideoInfo({required this.nombre, required this.videoBase64});

  Future<File> getVideoFile() async {
    final bytes = base64Decode(videoBase64);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$nombre.mp4');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }
}

Future<List<VideoInfo>> obtenerVideosDesdeTexto(String texto) async {
  final url = Uri.parse('http://192.168.100.3:8000/obtener_video/');
  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'texto': texto}),
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    final List videos = data['videos'];
    return videos
        .map((v) => VideoInfo(
              nombre: v['nombre'],
              videoBase64: v['video_base64'],
            ))
        .toList();
  } else {
    throw Exception('Error al obtener videos: ${response.body}');
  }
}
