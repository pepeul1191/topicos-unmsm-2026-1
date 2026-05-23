import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:road_eye/controllers/plate_controller.dart';
import 'package:road_eye/views/camera_view.dart';

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
    return GetMaterialApp(
      title: 'Lector de Placas Perú',
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.red,
        scaffoldBackgroundColor: Colors.black,
      ),
      home: const CameraView(),
      debugShowCheckedModeBanner: false,
    );
  }
}