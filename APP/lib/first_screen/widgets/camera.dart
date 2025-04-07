import 'dart:convert';
import 'dart:io';
import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:say_it/widgets/appBar.dart';
import 'package:http/http.dart' as http;

class CameraScreen extends StatefulWidget {
  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  bool _availableServer = false;
  bool _prediction = false;
  String prediction = "";

  XFile? _imageFile; // Archivo de la foto tomada
  Timer? _predictionTimer; // Timer para hacer la predicción cada 5 segundos

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    await getServerStatus();
    if (_availableServer) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green,
          content: Container(
              decoration: BoxDecoration(color: Colors.green),
              child: Text(textAlign: TextAlign.center, "Servidor disponible")),
          duration: Duration(seconds: 3), // Duración en pantalla
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
          content: Container(
              decoration: BoxDecoration(color: Colors.red),
              child:
                  Text(textAlign: TextAlign.center, "Servidor no disponible")),
          duration: Duration(seconds: 3), // Duración en pantalla
        ),
      );
    }

    _cameras = await availableCameras();
    if (_cameras!.isNotEmpty) {
      _cameraController = CameraController(
        _cameras![0], // Usa la cámara trasera
        ResolutionPreset.medium,
      );

      await _cameraController!.initialize();
      setState(() {
        _isCameraInitialized = true;
      });

      // Inicia el temporizador para hacer la predicción cada 5 segundos
      _startPredictionTimer();
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _predictionTimer?.cancel(); // Cancela el temporizador cuando se desmonte
    super.dispose();
  }

  void _startPredictionTimer() {
    _predictionTimer = Timer.periodic(Duration(seconds: 3), (timer) async {
      if (_cameraController == null || !_cameraController!.value.isInitialized)
        return;

      try {
        XFile image = await _cameraController!.takePicture();
        setState(() {
          _imageFile = image;
        });

        // Llama a la predicción del servidor
        await getServerPrediction(File(image.path).path, context);
      } catch (e) {
        print("Error al tomar foto: $e");
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(80),
        child: AppBarSayIt(),
      ),
      body: SingleChildScrollView(
          child: _isCameraInitialized
              ? Column(
                  children: [
                    Stack(
                      children: [
                        Padding(
                          padding: EdgeInsets.only(
                              top: 20, left: 20, right: 20, bottom: 20),
                          child: Transform.rotate(
                            angle: 90 * 3.1415927 / 180,
                            child: Container(
                              width: 350,
                              height: 370,
                              decoration: BoxDecoration(
                                border:
                                    Border.all(color: Colors.blue, width: 2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: CameraPreview(_cameraController!),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                            right: -5,
                            bottom: 5,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(100),
                              onTap: () async {
                                final picker = ImagePicker();
                                final XFile? pickedFile = await picker
                                    .pickImage(source: ImageSource.gallery);

                                if (pickedFile == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      behavior: SnackBarBehavior.floating,
                                      backgroundColor: Colors.red,
                                      content: Container(
                                          decoration:
                                              BoxDecoration(color: Colors.red),
                                          child: Text(
                                              textAlign: TextAlign.center,
                                              "No has seleccionado una imagen")),
                                      duration: Duration(
                                          seconds: 3), // Duración en pantalla
                                    ),
                                  );
                                  return;
                                }

                                File imageFile = File(pickedFile.path);
                                await getServerPrediction(
                                    imageFile.path, context);
                              },
                              child: Container(
                                margin: EdgeInsets.all(5),
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                    color: Colors.lightBlue,
                                    borderRadius: BorderRadius.circular(100)),
                                child: Icon(
                                  Icons.image,
                                  size: 30,
                                  color: Colors.white,
                                ),
                              ),
                            )),
                        Positioned(
                            bottom: 0,
                            left: 160,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(100),
                              onTap: () async {
                                if (_cameraController == null ||
                                    !_cameraController!.value.isInitialized)
                                  return;

                                try {
                                  XFile image =
                                      await _cameraController!.takePicture();
                                  setState(() {
                                    _imageFile = image;
                                  });

                                  await getServerPrediction(
                                      File(image.path).path, context);
                                } catch (e) {
                                  print("Error al tomar foto: $e");
                                }
                              },
                              child: Container(
                                margin: EdgeInsets.all(5),
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                    color: Colors.lightBlue,
                                    borderRadius: BorderRadius.circular(100)),
                                child: Icon(
                                  Icons.camera,
                                  size: 30,
                                  color: Colors.white,
                                ),
                              ),
                            )),
                      ],
                    ),
                    Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      child: Container(
                        height: 300,
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
                                  padding: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color.fromARGB(
                                        255, 248, 248, 248),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child:
                                      Text("La letra predecida es $prediction"),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  ],
                )
              : Center(
                  heightFactor: 20,
                  child: CircularProgressIndicator(
                    color: Colors.lightBlue,
                    strokeWidth: 6,
                  ))),
    );
  }

  Future<void> getServerStatus() async {
    var url = Uri.parse("http://192.168.100.3:8000/health");

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _availableServer = true;
        return data["status"];
      }
    } catch (e) {
      e;
    }
  }

  Future<void> getServerPrediction(String path, BuildContext context) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('http://192.168.100.3:8000/predict'),
    );

    request.files.add(
      await http.MultipartFile.fromPath('file', path),
    );

    try {
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      var jsonResponse = jsonDecode(response.body);

      if (streamedResponse.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green,
            content: Container(
                decoration: BoxDecoration(color: Colors.green),
                child: Text(
                    textAlign: TextAlign.center,
                    "predicción del modelo ${jsonResponse['prediction']}")),
            duration: Duration(seconds: 3), // Duración en pantalla
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.amber,
            content: Container(
                decoration: BoxDecoration(color: Colors.amber),
                child:
                    Text(textAlign: TextAlign.center, jsonResponse['detail'])),
            duration: Duration(seconds: 3), // Duración en pantalla
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
          content: Container(
              decoration: BoxDecoration(color: Colors.red),
              child:
                  Text(textAlign: TextAlign.center, "Error de conexión: $e")),
          duration: Duration(seconds: 3), // Duración en pantalla
        ),
      );
      print("Error de conexión: $e");
    }
  }
}
