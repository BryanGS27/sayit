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
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _controller = TextEditingController();
  List<VideoPlayerController?> controllers = [];
  List<MediaInfo> media = [];
  int currentMediaIndex = 0;
  bool isLoading = false;
  bool noHuboVideos = true;
  int _reproduccionId = 0;

  @override
  void initState() {
    super.initState();
    setState(() {});
  }

  @override
  void dispose() {
    for (final controller in controllers) {
      controller
          ?.dispose(); // Asegúrate de que el controlador de video se libere
    }
    _scrollController
        .dispose(); // El controlador de desplazamiento también se debe liberar
    super.dispose();
  }

  void reproducirMediaDesde(int index, {int? reproduccionId}) async {
    if (index >= media.length) return; // No hay más contenido

    final actualId = reproduccionId ?? DateTime.now().millisecondsSinceEpoch;
    _reproduccionId = actualId;

    // Asegúrate de que la animación de desplazamiento solo ocurra cuando el scroll esté listo
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        370.0 * index,
        duration: Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }

    currentMediaIndex = index;
    setState(
        () {}); // Actualiza el estado para que el índice se refleje en la UI

    if (media[index].esImagen) {
      await Future.delayed(Duration(
          milliseconds:
              10)); // Pequeña espera para asegurar que la imagen se haya mostrado
      await Future.delayed(
          Duration(seconds: 2)); // Espera de 2 segundos para la imagen
      if (_reproduccionId != actualId)
        return; // Asegúrate de que no se haya cambiado el ID de reproducción
      // Avanza al siguiente medio (imagen o video)
      reproducirMediaDesde(index + 1, reproduccionId: actualId);
    } else {
      final controller = controllers[index]!;

      // Espera hasta que el video esté completamente inicializado
      if (!controller.value.isInitialized) {
        await controller.initialize();
      }

      await controller.seekTo(Duration.zero); // Reinicia el video al principio
      await controller.play(); // Comienza a reproducir el video

      // Agrega un listener para comprobar cuando el video haya terminado
      controller.addListener(() async {
        final isFinished =
            controller.value.position >= controller.value.duration &&
                !controller.value.isPlaying;

        if (isFinished && index == currentMediaIndex) {
          controller.removeListener(
              () {}); // Elimina el listener después de la reproducción
          // Avanza al siguiente medio (imagen o video)
          if (_reproduccionId == actualId) {
            reproducirMediaDesde(index + 1, reproduccionId: actualId);
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Cierra el teclado
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(80),
          child: AppBarSayIt(),
        ),
        body: SingleChildScrollView(
          child: GestureDetector(
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
                      padding:
                          const EdgeInsets.only(top: 8.0, right: 8, left: 8),
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
                                  hintText: "Ingresa tu texto a traducir",
                                ),
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                  onPressed: () async {
                                    FocusScope.of(context).unfocus();
                                    setState(() {
                                      isLoading = true;
                                    });
                                    media = await obtenerMediaDesdeTexto(
                                        _controller.text);
                                    for (final controller in controllers) {
                                      await controller?.dispose();
                                    }
                                    controllers.clear();

                                    for (int i = 0; i < media.length; i++) {
                                      if (media[i].esImagen) {
                                        controllers.add(null);
                                      } else {
                                        final file =
                                            await media[i].getMediaFile();
                                        final controller =
                                            VideoPlayerController.file(file);
                                        await controller.initialize();
                                        controllers.add(controller);
                                      }
                                    }

                                    currentMediaIndex = 0;
                                    reproducirMediaDesde(currentMediaIndex);

                                    setState(() {
                                      isLoading = false;
                                      if (media.isEmpty) {
                                        noHuboVideos = false;
                                      } else {
                                        noHuboVideos = true;
                                      }
                                      print("noHuboVideos $noHuboVideos");
                                    });
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
                isLoading == true
                    ? Container(
                        padding: EdgeInsets.only(top: 200),
                        child: CircularProgressIndicator(
                          color: Colors.blue,
                        ))
                    : media.isNotEmpty
                        ? Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 30),
                            child: Container(
                              height: 400,
                              decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(color: Colors.blue),
                                  borderRadius: BorderRadius.circular(16)),
                              child: Padding(
                                padding: const EdgeInsets.only(
                                    top: 8.0, right: 8, left: 8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Container(
                                        width: double.infinity,
                                        //padding: EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: const Color.fromARGB(
                                              255, 248, 248, 248),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: controllers.isEmpty
                                            ? Center(
                                                child:
                                                    CircularProgressIndicator())
                                            : ListView.builder(
                                                controller: _scrollController,
                                                scrollDirection:
                                                    Axis.horizontal,
                                                itemCount: media.length,
                                                itemBuilder: (context, index) {
                                                  final item = media[index];
                                                  final controller =
                                                      controllers[index];
                                                  return SizedBox(
                                                    width: 370,
                                                    child: Column(
                                                      children: [
                                                        Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .all(8.0),
                                                          child: Text(
                                                            item.nombre
                                                                .toUpperCase(),
                                                            style: TextStyle(
                                                                fontSize: 25,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                fontStyle:
                                                                    FontStyle
                                                                        .italic),
                                                          ),
                                                        ),
                                                        item.esImagen
                                                            ? FutureBuilder<
                                                                File>(
                                                                future: item
                                                                    .getMediaFile(),
                                                                builder: (context,
                                                                    snapshot) {
                                                                  if (snapshot.connectionState ==
                                                                          ConnectionState
                                                                              .done &&
                                                                      snapshot
                                                                          .hasData) {
                                                                    return Image.file(
                                                                        snapshot
                                                                            .data!,
                                                                        fit: BoxFit
                                                                            .contain,
                                                                        height:
                                                                            250);
                                                                  } else {
                                                                    return CircularProgressIndicator();
                                                                  }
                                                                },
                                                              )
                                                            : AspectRatio(
                                                                aspectRatio:
                                                                    controller!
                                                                        .value
                                                                        .aspectRatio,
                                                                child: VideoPlayer(
                                                                    controller),
                                                              ),
                                                      ],
                                                    ),
                                                  );
                                                },
                                              ),
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () {
                                        if (media.isNotEmpty) {
                                          reproducirMediaDesde(0);
                                        }
                                      },
                                      icon: Icon(
                                        Icons.replay,
                                        color: Colors.blue,
                                        size: 30.0,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                        : noHuboVideos
                            ? SizedBox()
                            : SizedBox(
                                child: Padding(
                                padding: const EdgeInsets.only(top: 150.0),
                                child: Text(
                                  "Lo Sentimos\nNo pudimos traducir el texto ingresado.",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontStyle: FontStyle.italic),
                                ),
                              )),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<List<MediaInfo>> obtenerMediaDesdeTexto(String texto) async {
    final url = Uri.parse('http://157.245.10.241:8000/obtener_video/');

    print("ya entró");
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'texto': texto}),
      );
      print("respuesta recibida");
      print(response.statusCode); // Ver el status code
      print(response.body); // Ver el cuerpo de la respuesta

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List items = data['videos'];
        return items
            .map((v) => MediaInfo(
                  nombre: v['nombre'],
                  mediaBase64: v['video_base64'],
                  esImagen: v['es_imagen'] ?? false, // El backend debe enviarlo
                ))
            .toList();
      } else {
        print("Error: ${response.statusCode}");
        throw Exception('Error al obtener medios');
      }
    } catch (e) {
      print("$noHuboVideos Error en la petición: $e");
      final List<MediaInfo> items = [];
      return items;
      throw Exception('Error al obtener medios');
    }
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

class MediaInfo {
  final String nombre;
  final String mediaBase64;
  final bool esImagen;

  MediaInfo(
      {required this.nombre,
      required this.mediaBase64,
      required this.esImagen});

  Future<File> getMediaFile() async {
    final bytes = base64Decode(mediaBase64);
    final dir = await getTemporaryDirectory();
    final ext = esImagen ? 'png' : 'mp4';
    final file = File('${dir.path}/$nombre.$ext');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }
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
