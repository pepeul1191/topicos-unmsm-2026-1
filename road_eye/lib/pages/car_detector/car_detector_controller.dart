// lib/pages/car_detector/car_detector_controller.dart
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:road_eye/configs/constants.dart';

class CarDetectorController extends GetxController {
  // Cámara
  CameraController? cameraController;
  final isCameraReady = false.obs;
  
  // Detección
  final vehiclesCount = 0.obs;
  final isDetecting = false.obs;
  final processedImage = ''.obs;
  final detections = <Map<String, dynamic>>[].obs;
  
  // Configuración
  final selectedModel = 'yolo11n'.obs;
  final fps = '0 fps'.obs;
  int frameCount = 0;
  Timer? fpsTimer;
  Timer? detectionTimer;
  
  final List<Map<String, String>> models = [
    {'value': 'yolo11n', 'label': 'YOLO11 Nano (más rápido)'},
    {'value': 'yolo11s', 'label': 'YOLO11 Small (más preciso)'},
    {'value': 'yolov8n', 'label': 'YOLOv8 Nano'},
    {'value': 'yolov8s', 'label': 'YOLOv8 Small'},
  ];
  
  @override
  void onInit() {
    super.onInit();
    _initCamera();
    _startFpsCounter();
  }
  
  @override
  void onClose() {
    _stopDetection();
    fpsTimer?.cancel();
    cameraController?.dispose();
    super.onClose();
  }
  
  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        print('❌ No hay cámaras disponibles');
        return;
      }
      
      final camera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      
      cameraController = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      
      await cameraController!.initialize();
      isCameraReady.value = true;
      _startDetection();
      
      if (kDebugMode) {
        print('✅ Cámara inicializada');
      }
    } catch (e) {
      print('❌ Error inicializando cámara: $e');
    }
  }
  
  void _startDetection() {
    detectionTimer?.cancel();
    detectionTimer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
      if (isCameraReady.value && !isDetecting.value) {
        _captureAndDetect();
      }
    });
  }
  
  void _stopDetection() {
    detectionTimer?.cancel();
    detectionTimer = null;
  }
  
  Future<void> _captureAndDetect() async {
    if (cameraController == null || !cameraController!.value.isInitialized) {
      return;
    }
    
    isDetecting.value = true;
    
    try {
      final XFile image = await cameraController!.takePicture();
      final bytes = await image.readAsBytes();
      await _sendToServer(bytes);
      frameCount++;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error capturando: $e');
      }
    } finally {
      isDetecting.value = false;
    }
  }
  
  // VERSIÓN CORREGIDA - Usar http.post con multipart manual
  Future<void> _sendToServer(Uint8List imageBytes) async {
    try {
      final uri = Uri.parse('${Constants.yoloBaseUrl}/detect');
      
      // Crear el boundary para multipart
      final boundary = '----${DateTime.now().millisecondsSinceEpoch}';
      
      // Construir el body manualmente
      final List<int> body = [];
      
      // Agregar campo model_name
      body.addAll(_textToBytes('--$boundary\r\n'));
      body.addAll(_textToBytes('Content-Disposition: form-data; name="model_name"\r\n\r\n'));
      body.addAll(_textToBytes('${selectedModel.value}\r\n'));
      
      // Agregar archivo
      body.addAll(_textToBytes('--$boundary\r\n'));
      body.addAll(_textToBytes('Content-Disposition: form-data; name="image"; filename="frame.jpg"\r\n'));
      body.addAll(_textToBytes('Content-Type: image/jpeg\r\n\r\n'));
      body.addAll(imageBytes);
      body.addAll(_textToBytes('\r\n'));
      
      // Cerrar boundary
      body.addAll(_textToBytes('--$boundary--\r\n'));
      
      // Enviar request
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'multipart/form-data; boundary=$boundary',
        },
        body: body,
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['success'] == true) {
          vehiclesCount.value = data['vehicles_count'] ?? 0;
          processedImage.value = data['processed_image'] ?? '';
          detections.value = List<Map<String, dynamic>>.from(data['detections'] ?? []);
        } else {
          print('❌ Error en detección: ${data['error']}');
        }
      } else {
        print('❌ Error HTTP: ${response.statusCode}');
        print('Respuesta: ${response.body}');
      }
      
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error enviando al servidor: $e');
      }
    }
  }
  
  List<int> _textToBytes(String text) {
    return utf8.encode(text);
  }
  
  void _startFpsCounter() {
    fpsTimer?.cancel();
    fpsTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      fps.value = '$frameCount fps';
      frameCount = 0;
    });
  }
  
  void updateModel(String value) {
    selectedModel.value = value;
  }
  
  Future<void> restartCamera() async {
    await cameraController?.dispose();
    await _initCamera();
  }
}