// lib/main.dart
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:road_eye/configs/theme.dart';
import 'package:road_eye/pages/about/about_page.dart';
import 'package:road_eye/pages/home/home_page.dart';
import 'package:road_eye/pages/plate_reader/plate_reader_binding.dart';
import 'package:road_eye/pages/plate_reader/plate_reader_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Obtener cámaras disponibles y guardarlas para usarlas después
  final cameras = await availableCameras();
  
  // Guardar las cámaras en una variable global o singleton
  Get.put<CameraData>(CameraData(cameras));
  
  runApp(const PlacasApp());
}

// Clase para almacenar las cámaras globalmente
class CameraData {
  final List<CameraDescription> cameras;
  CameraData(this.cameras);
}

class PlacasApp extends StatelessWidget {
  const PlacasApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    final TextTheme baseTextTheme = Typography.material2021().englishLike;
    final MaterialTheme materialTheme = MaterialTheme(baseTextTheme);

    return GetMaterialApp(
      title: 'Road Eye',
      theme: materialTheme.light(),
      darkTheme: materialTheme.dark(),
      debugShowCheckedModeBanner: false,
      initialRoute: '/home',
      getPages: [
        GetPage(name: '/home', page: () => const HomePage()),
        GetPage(name: '/about', page: () => const AboutPage()),
        GetPage(
          name: '/plate-reader', 
          page: () => const PlateReaderPage(),
          binding: PlateReaderBinding(), // Binding para inicializar el controlador
        ),
      ],
    );
  }
}