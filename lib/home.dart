import 'dart:typed_data';

import 'package:camera/camera.dart' as Camera;
import 'package:flutter/material.dart';
import 'package:flutter_tflite/flutter_tflite.dart';
import 'package:image/image.dart' as img;
import 'main.dart';

class CameraScreen  extends StatefulWidget {
  const CameraScreen ({Key? key}): super(key: key);

  @override
  State<CameraScreen > createState() => _HomeState();
}

class _HomeState extends State<CameraScreen > {
  Camera.CameraImage? cameraImage;
  Camera.CameraController? cameraController;
  String output = '';
  bool _modelLoaded = false;

  @override
  void initState() {
    super.initState();
    loadCamera();
    loadModel();
  }

  loadCamera() {
    cameraController = Camera.CameraController(cameras![0], Camera.ResolutionPreset.medium);
    cameraController!.initialize().then((value) {
      if (!mounted) {
        return;
      } else {
        setState(() {
          try {
            cameraController!.startImageStream((imageStream) {
              // Print message for each frame received
              print("Frame received");
              // Commented out to avoid running the model for debugging
              cameraImage = imageStream;
              runModel();
            });
          } catch (e) {
            print("Error starting image stream: $e");
          }
        });
      }
    }).catchError((e) {
      print("Error initializing camera: $e");
    });
  }


  runModel() async {
    print("------------------->Prediction called");
    //if(Tflite.)
    if(_modelLoaded){
      print("El modelito ya esta");
    }
    else{
      print("No hay modelito");
      //return;
    }
    if (cameraImage != null) {
      var predictions = await Tflite.runModelOnFrame(
        bytesList: cameraImage!.planes.map((plane) {
          return plane.bytes;
        }).toList(),
        imageHeight: cameraImage!.height,
        imageWidth: cameraImage!.width,
        imageMean: 127.5,
        imageStd: 127.5,
        rotation: 90,
        //numResults: 2,
        threshold: 0.1,
        asynch: true,
      );

      //print("------------------->"+predictions!.first['label']);

      setState(() {
        output = predictions!.first['label'];
      });
      // predictions!.forEach((element) {
      //   setState(() {
      //     output = element['label'];
      //   });
      // });
    }
  }


  Future<void> loadModel() async {
    try {
      var result = await Tflite.loadModel(
          model: "assets/model.tflite",
          labels: "assets/labels.txt",
          isAsset: true, // defaults to true, set to false to load resources outside assets
          useGpuDelegate: false
      );
      setState(() {
        _modelLoaded = true;
      });
    } catch (e) {
      print("Failed to load model: $e");
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('deteccion de figuras'),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(20),
            child: Container(
              height: MediaQuery.of(context).size.height * 0.7,
              width: MediaQuery.of(context).size.width,
              child: !cameraController!.value.isInitialized
                  ? Container()
                  : AspectRatio(
                aspectRatio: cameraController!.value.aspectRatio,
                child: Camera.CameraPreview(cameraController!),
              ),
            ),
          ),
          Text(
            output,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ],
      ),
    );
  }
}


class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Detección de Figuras'),
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/fondo.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CameraScreen()),
              );
            },
            child: Text('Abrir Cámara'),
          ),
        ),
      ),
    );
  }
}
