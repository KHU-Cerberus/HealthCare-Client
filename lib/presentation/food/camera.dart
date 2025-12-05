import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:health_care/presentation/food/display_picture.dart';
import 'package:health_care/core/camera/camera_config.dart';

class CameraPage extends StatefulWidget {
  final String jwt;
  final String baseUrl;

  const CameraPage({super.key, required this.baseUrl, required this.jwt});
  @override
  _CameraPageState createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;

  @override
  void initState() {
    super.initState();
    _controller = CameraController(
      cameras[0],             // 0 = 후면카메라, 1 = 전면카메라
      ResolutionPreset.medium,
    );
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Camera Demo')),
      body: FutureBuilder(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return CameraPreview(_controller);
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.camera),
        onPressed: () async {
          await _initializeControllerFuture;
          final image = await _controller.takePicture();
          print('사진 저장 위치: ${image.path}');

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DisplayPictureScreen(imagePath: image.path),
            ),
          );
        },
      ),
    );
  }
}
