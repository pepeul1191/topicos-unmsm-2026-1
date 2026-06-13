// lib/pages/car_detector/car_detector_controller.dart
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:road_eye/configs/constants.dart';
import 'package:image/image.dart' as img;

class CarDetectorController extends GetxController {
  // Cámara
  CameraController? cameraController;
  final isCameraReady = false.obs;
  
  // WebSocket
  WebSocketChannel? webSocketChannel;
  final isConnected = false.obs;
  final connectionStatus = '⚪ Desconectado'.obs;
  
  // Detección
  final vehiclesCount = 0.obs;
  final isDetecting = false.obs;
  final processedImage = ''.obs; // Base64 de imagen procesada
  final detections = <Map<String, dynamic>>[].obs;
  
  // Configuración
  final selectedModel = 'yolo11n'.obs;
  
  // Captura de frames
  Timer? frameTimer;
  bool _isCapturing = false;
  int frameCount = 0;
  final fps = '0 fps'.obs;
  Timer? fpsTimer;
  
  // Modelos disponibles
  final List<Map<String, String>> models = [
    {'value': 'yolo11n', 'label': 'YOLO11 Nano (más rápido)'},
    {'value': 'yolo11s', 'label': 'YOLO11 Small (más preciso)'},
    {'value': 'yolov8n', 'label': 'YOLOv8 Nano'},
    {'value': 'yolov8s', 'label': 'YOLOv8 Small'},
  ];
  
  // Control de estado
  bool _isDisposing = false;
  
  @override
  void onInit() {
    super.onInit();
    _initCamera();
    _connectWebSocket();
    _startFpsCounter();
  }
  
  @override
  void onClose() {
    _isDisposing = true;
    _disconnectWebSocket();
    frameTimer?.cancel();
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
        ResolutionPreset.low, // Usar baja resolución para mejor rendimiento
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      
      await cameraController!.initialize();
      isCameraReady.value = true;
      
      if (kDebugMode) {
        print('✅ Cámara inicializada');
      }
    } catch (e) {
      print('❌ Error inicializando cámara: $e');
    }
  }
  
  Future<void> _connectWebSocket() async {
    if (_isDisposing) return;
    
    try {
      final wsUrl = '${Constants.yoloBaseUrl.replaceFirst('http', 'ws')}/ws/detect';
      print('🔄 Conectando WebSocket a $wsUrl');
      
      webSocketChannel = WebSocketChannel.connect(Uri.parse(wsUrl));
      
      webSocketChannel!.stream.listen(
        (message) {
          if (!_isDisposing) {
            _handleWebSocketMessage(message);
          }
        },
        onDone: () {
          if (!_isDisposing) {
            print('🔌 WebSocket desconectado');
            isConnected.value = false;
            connectionStatus.value = '⚪ Desconectado';
          }
        },
        onError: (error) {
          if (!_isDisposing) {
            print('❌ WebSocket error: $error');
            isConnected.value = false;
            connectionStatus.value = '❌ Error de conexión';
          }
        },
      );
      
      isConnected.value = true;
      connectionStatus.value = '✅ Conectado';
      
      // Enviar configuración inicial
      _sendConfig();
      
      // Iniciar captura de frames
      _startFrameCapture();
      
    } catch (e) {
      print('❌ Error conectando WebSocket: $e');
      isConnected.value = false;
      connectionStatus.value = '❌ Error de conexión';
    }
  }
  
  void _disconnectWebSocket() {
    if (webSocketChannel != null) {
      webSocketChannel!.sink.close();
      webSocketChannel = null;
    }
    isConnected.value = false;
  }
  
  void _sendConfig() {
    if (webSocketChannel != null && isConnected.value) {
      webSocketChannel!.sink.add(jsonEncode({
        'type': 'config',
        'model': selectedModel.value,
      }));
    }
  }
  
  void _startFrameCapture() {
    frameTimer?.cancel();
    // Capturar cada 200ms (5 fps)
    frameTimer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
      if (isCameraReady.value && isConnected.value && !_isCapturing && !_isDisposing) {
        _captureAndSendFrame();
      }
    });
  }
  
  Future<void> _captureAndSendFrame() async {
    if (cameraController == null || !cameraController!.value.isInitialized) {
      return;
    }
    
    _isCapturing = true;
    
    try {
      // Capturar imagen
      final XFile image = await cameraController!.takePicture();
      final bytes = await image.readAsBytes();
      
      // Comprimir para reducir tamaño
      final compressedBytes = await _compressImage(bytes);
      final base64Image = base64Encode(compressedBytes);
      
      // Enviar por WebSocket
      if (webSocketChannel != null && isConnected.value && !_isDisposing) {
        webSocketChannel!.sink.add(jsonEncode({
          'type': 'frame',
          'image': base64Image,
        }));
      }
      
      // Actualizar contador de frames
      frameCount++;
      
    } catch (e) {
      if (!_isDisposing && kDebugMode) {
        print('❌ Error capturando frame: $e');
      }
    } finally {
      _isCapturing = false;
    }
  }
  
  Future<Uint8List> _compressImage(Uint8List bytes) async {
    try {
      final image = img.decodeImage(bytes);
      if (image == null) return bytes;
      
      final resized = img.copyResize(image, width: 320);
      final compressed = img.encodeJpg(resized, quality: 60);
      
      return Uint8List.fromList(compressed);
    } catch (e) {
      return bytes;
    }
  }
  
  void _handleWebSocketMessage(dynamic message) {
    try {
      final data = jsonDecode(message);
      final type = data['type'];
      
      if (type == 'connected') {
        print('✅ ${data['message']}');
        connectionStatus.value = '✅ Conectado - ${data['message']}';
        
      } else if (type == 'config_ack') {
        print('✅ ${data['message']}');
        
      } else if (type == 'detection') {
        // Actualizar resultados
        vehiclesCount.value = data['vehicles_count'] ?? 0;
        processedImage.value = data['processed_image'] ?? '';
        detections.value = List<Map<String, dynamic>>.from(data['detections'] ?? []);
        
      } else if (type == 'error') {
        print('❌ Error del servidor: ${data['message']}');
        connectionStatus.value = '⚠️ Error: ${data['message']}';
        
      } else if (type == 'pong') {
        // Respuesta a ping, ignorar
      }
      
    } catch (e) {
      print('❌ Error parseando mensaje: $e');
    }
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
    // Enviar nueva configuración al servidor
    if (isConnected.value && webSocketChannel != null) {
      webSocketChannel!.sink.add(jsonEncode({
        'type': 'config',
        'model': value,
      }));
    }
  }
  
  Future<void> reconnectWebSocket() async {
    if (_isDisposing) return;
    
    print('🔄 Reconectando WebSocket...');
    connectionStatus.value = '🔄 Reconectando...';
    
    _disconnectWebSocket();
    await Future.delayed(const Duration(milliseconds: 500));
    await _connectWebSocket();
  }
  
  void clearResults() {
    processedImage.value = '';
    vehiclesCount.value = 0;
    detections.clear();
  }
}
