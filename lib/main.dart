import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:health_care/presentation/login/login.dart';
import 'core/camera/camera_config.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras(); // 사용 가능한 카메라 목록 가져오기
  await dotenv.load(fileName: '.env');
  String baseUrl = dotenv.env['SERVER_URL'] ?? "";
  runApp(MyApp(
    baseUrl: baseUrl,
  ));

}

class MyApp extends StatelessWidget {
  
  final String baseUrl;

  const MyApp({super.key, required this.baseUrl});
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Health Care App',
      home: LoginPage(baseUrl: baseUrl),
    );
  }
}