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


  img.Image convertToGrayscale(img.Image image) {
    img.Image grayscaleImage = img.Image(image.width, image.height);
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        int pixel = image.getPixel(x, y);
        int luma = (0.299 * img.getRed(pixel) +
            0.587 * img.getGreen(pixel) +
            0.114 * img.getBlue(pixel)).round();
        grayscaleImage.setPixelRgba(x, y, luma, luma, luma);
      }
    }
    return grayscaleImage;
  }


  Uint8List imageToByteListFloat32(
      img.Image image, int inputSize, double mean, double std) {
    var convertedBytes = Float32List(1 * inputSize * inputSize * 3);
    var buffer = Float32List.view(convertedBytes.buffer);
    int pixelIndex = 0;
    for (var i = 0; i < inputSize; i++) {
      for (var j = 0; j < inputSize; j++) {
        var pixel = image.getPixel(j, i);
        buffer[pixelIndex++] = (img.getRed(pixel) - mean) / std;
        buffer[pixelIndex++] = (img.getGreen(pixel) - mean) / std;
        buffer[pixelIndex++] = (img.getBlue(pixel) - mean) / std;
      }
    }
    return convertedBytes.buffer.asUint8List();
  }

  Uint8List imageToByteListUint8(img.Image image, int inputSize) {
    var convertedBytes = Uint8List(1 * inputSize * inputSize * 3);
    var buffer = Uint8List.view(convertedBytes.buffer);
    int pixelIndex = 0;
    for (var i = 0; i < inputSize; i++) {
      for (var j = 0; j < inputSize; j++) {
        var pixel = image.getPixel(j, i);
        buffer[pixelIndex++] = img.getRed(pixel);
        buffer[pixelIndex++] = img.getGreen(pixel);
        buffer[pixelIndex++] = img.getBlue(pixel);
      }
    }
    return convertedBytes.buffer.asUint8List();
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

      img.Image image = img.Image.fromBytes(
        cameraImage!.width,
        cameraImage!.height,
        cameraImage!.planes[0].bytes,
        format: img.Format.bgra,
      );
      img.Image grayscaleImage = convertToGrayscale(image);

      // Resize the grayscale image to the model's input size
      img.Image resizedImage = img.copyResize(grayscaleImage, width: 224, height: 224);

      // Convert the resized grayscale image to binary format
      Uint8List binary = imageToByteListFloat32(resizedImage, 224, 127.5, 127.5);

      var predictions =

      // await Tflite.detectObjectOnFrame(
      //     bytesList: cameraImage!.planes.map((plane) {return plane.bytes;}).toList(),// required
      //     model: "YOLO",
      //     imageHeight: cameraImage!.height,
      //     imageWidth: cameraImage!.width,
      //     imageMean: 0,         // defaults to 127.5
      //     imageStd: 255.0,      // defaults to 127.5
      //     //numResults: 2,        // defaults to 5
      //     threshold: 0.1,       // defaults to 0.1
      //     numResultsPerClass: 2,// defaults to 5
      //     //anchors: anchors,     // defaults to [0.57273,0.677385,1.87446,2.06253,3.33843,5.47434,7.88282,3.52778,9.77052,9.16828]
      //     blockSize: 32,        // defaults to 32
      //     numBoxesPerBlock: 5,  // defaults to 5
      //     asynch: true          // defaults to true
      // );

      await Tflite.runModelOnBinary(
        binary: binary,
        numResults: 6,
        threshold: 0.05,
        asynch: true,
      );

      // await Tflite.runModelOnFrame(
      //   bytesList: cameraImage!.planes.map((plane) {
      //     return plane.bytes;
      //   }).toList(),
      //   imageHeight: cameraImage!.height,
      //   imageWidth: cameraImage!.width,
      //   imageMean: 127.5,
      //   imageStd: 127.5,
      //   rotation: 90,
      //   //numResults: 2,
      //   threshold: 0.1,
      //   asynch: true,
      // );

      //print("------------------->"+predictions!.first['label']);

      var label = "";
      double max = 0;
      for(var ele in predictions!){
        //print("---------------------------------->" + ele['confidence'].toString());
        if(ele['confidence'] >= max){
          label = ele['label'];
          max = ele['confidence'];
        }
      }

      max = ((max*100).round()).toDouble()/100;
      setState(() {
        output = label + "\n Certeza: ${max.toString()}%";
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
        model: "assets/model_unquant.tflite",
        labels: "assets/labels_1.txt",
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

