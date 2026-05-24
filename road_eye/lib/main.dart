import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:road_eye/configs/theme.dart';
import 'package:road_eye/pages/about/about_page.dart';
import 'package:road_eye/pages/home/home_page.dart';
import 'package:road_eye/pages/plate1/plate_view.dart';
import 'package:road_eye/pages/plate1/plate_controller.dart';
import 'package:road_eye/pages/plate1/plate_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Obtener cámaras disponibles
  final cameras = await availableCameras();
  final camera = cameras.firstWhere(
    (c) => c.lensDirection == CameraLensDirection.back,
    orElse: () => cameras.first,
  );
  
  // Inicializar GetX con el controlador
  Get.put(PlateController(camera: camera));
  
  runApp(const PlacasApp());
}

class PlacasApp extends StatelessWidget {
  const PlacasApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    final TextTheme baseTextTheme = Typography.material2021().englishLike;
    final MaterialTheme materialTheme = MaterialTheme(baseTextTheme);
    //final colors = Theme.of(context).colorScheme;

    return GetMaterialApp(
      title: 'Lector de Placas Perú',
      theme: materialTheme.light(),
      darkTheme: materialTheme.dark(),
      debugShowCheckedModeBanner: false,
      initialRoute: '/home',
      routes: {
        '/home': (context) => HomePage(),
        '/about': (context) => AboutPage()
      },
    );
  }
}