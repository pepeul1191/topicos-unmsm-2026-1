// lib/pages/car_detector/car_detector_controller.dart
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:road_eye/configs/constants.dart';
import 'package:image/image.dart' as img;

class CarDetectorController extends GetxController {
  // Cámara (se usa solo para capturar, NO se muestra)
  CameraController? cameraController;
  final isCameraReady = false.obs;
  
  // WebSocket
  WebSocketChannel? webSocketChannel;
  final isConnected = false.obs;
  final connectionStatus = '⚪ Desconectado'.obs;
  
  // Detección - SOLO mostrar la imagen procesada del servidor
  final processedImage = ''.obs; // Imagen procesada por YOLO
  final vehiclesCount = 0.obs;
  final detections = <Map<String, dynamic>>[].obs;
  final isStreaming = false.obs;
  final lastDetection = ''.obs;
  
  // Métricas
  final fps = '0 fps'.obs;
  int frameCount = 0;
  Timer? fpsTimer;
  Timer? streamTimer;
  bool _isSending = false;
  
  // Configuración
  final selectedModel = 'yolo11n'.obs;
  
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
    stopStreaming();
    _disconnectWebSocket();
    fpsTimer?.cancel();
    streamTimer?.cancel();
    cameraController?.dispose();
    super.onClose();
  }
  
  // ============= INICIALIZACIÓN DE CÁMARA =============
  
  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        print('❌ No hay cámaras disponibles');
        connectionStatus.value = '❌ No hay cámara';
        return;
      }
      
      final camera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      
      cameraController = CameraController(
        camera,
        ResolutionPreset.low, // Baja resolución para mejor rendimiento
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      
      await cameraController!.initialize();
      isCameraReady.value = true;
      
      if (kDebugMode) {
        print('✅ Cámara inicializada (modo oculto)');
      }
    } catch (e) {
      print('❌ Error inicializando cámara: $e');
      connectionStatus.value = '❌ Error de cámara';
    }
  }
  
  // ============= WEBSOCKET =============
  
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
            isStreaming.value = false;
          }
        },
        onError: (error) {
          if (!_isDisposing) {
            print('❌ WebSocket error: $error');
            isConnected.value = false;
            connectionStatus.value = '❌ Error de conexión';
            isStreaming.value = false;
          }
        },
      );
      
      isConnected.value = true;
      connectionStatus.value = '✅ Conectado';
      
      // Enviar configuración inicial
      _sendConfig();
      
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
    isStreaming.value = false;
  }
  
  void _sendConfig() {
    if (webSocketChannel != null && isConnected.value) {
      webSocketChannel!.sink.add(jsonEncode({
        'type': 'config',
        'model': selectedModel.value,
      }));
    }
  }
  
  void _handleWebSocketMessage(dynamic message) {
    try {
      final data = jsonDecode(message);
      final type = data['type'];
      
      if (type == 'connected') {
        print('✅ ${data['message']}');
        connectionStatus.value = '✅ Conectado';
        
      } else if (type == 'config_ack') {
        print('✅ ${data['message']}');
        
      } else if (type == 'detection') {
        // Actualizar la imagen procesada y resultados en tiempo real
        processedImage.value = data['processed_image'] ?? '';
        vehiclesCount.value = data['vehicles_count'] ?? 0;
        detections.value = List<Map<String, dynamic>>.from(data['detections'] ?? []);
        
        // Guardar última detección relevante
        if (detections.isNotEmpty) {
          lastDetection.value = detections.first['label'];
        }
        
      } else if (type == 'error') {
        print('❌ Error del servidor: ${data['message']}');
        connectionStatus.value = '⚠️ Error: ${data['message']}';
      }
      
    } catch (e) {
      print('❌ Error parseando mensaje: $e');
    }
  }
  
  // ============= STREAMING =============
  
  void startStreaming() {
    if (streamTimer != null) {
      print('⚠️ Streaming ya está activo');
      return;
    }
    
    if (!isCameraReady.value) {
      Get.snackbar(
        'Error',
        'Cámara no disponible',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }
    
    if (!isConnected.value) {
      Get.snackbar(
        'Error de conexión',
        'No hay conexión con el servidor',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }
    
    isStreaming.value = true;
    processedImage.value = ''; // Limpiar imagen anterior
    
    // Enviar frames cada 150ms (~6-7 fps)
    streamTimer = Timer.periodic(const Duration(milliseconds: 150), (timer) {
      if (isStreaming.value && isCameraReady.value && isConnected.value && !_isSending && !_isDisposing) {
        _sendFrame();
      }
    });
    
    print('🎥 Streaming iniciado - Mostrando SOLO imagen procesada');
    Get.snackbar(
      'Streaming',
      'Streaming iniciado. Mostrando detecciones en tiempo real.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green,
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
    );
  }
  
  void stopStreaming() {
    isStreaming.value = false;
    streamTimer?.cancel();
    streamTimer = null;
    
    // Limpiar imagen al detener
    processedImage.value = '';
    
    print('🛑 Streaming detenido');
    Get.snackbar(
      'Streaming',
      'Streaming detenido',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.orange,
      colorText: Colors.white,
    );
  }
  
  Future<void> _sendFrame() async {
    if (cameraController == null || !cameraController!.value.isInitialized) {
      return;
    }
    
    _isSending = true;
    
    try {
      // Capturar frame
      final XFile image = await cameraController!.takePicture();
      final bytes = await image.readAsBytes();
      
      // Comprimir para reducir ancho de banda
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
        print('❌ Error enviando frame: $e');
      }
    } finally {
      _isSending = false;
    }
  }
  
  Future<Uint8List> _compressImage(Uint8List bytes) async {
    try {
      final image = img.decodeImage(bytes);
      if (image == null) return bytes;
      
      // Reducir tamaño para mejor rendimiento
      final resized = img.copyResize(image, width: 320);
      final compressed = img.encodeJpg(resized, quality: 60);
      
      return Uint8List.fromList(compressed);
    } catch (e) {
      return bytes;
    }
  }
  
  // ============= MÉTRICAS =============
  
  void _startFpsCounter() {
    fpsTimer?.cancel();
    fpsTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      fps.value = '$frameCount fps';
      frameCount = 0;
    });
  }
  
  // ============= CONFIGURACIÓN =============
  
  void updateModel(String value) {
    selectedModel.value = value;
    if (isConnected.value && webSocketChannel != null) {
      webSocketChannel!.sink.add(jsonEncode({
        'type': 'config',
        'model': value,
      }));
    }
  }
  
  // ============= UTILIDADES =============
  
  void clearResults() {
    processedImage.value = '';
    vehiclesCount.value = 0;
    detections.clear();
    lastDetection.value = '';
  }
  
  Future<void> reconnectWebSocket() async {
    if (_isDisposing) return;
    
    print('🔄 Reconectando WebSocket...');
    connectionStatus.value = '🔄 Reconectando...';
    
    // Detener streaming
    final wasStreaming = isStreaming.value;
    if (wasStreaming) {
      stopStreaming();
    }
    
    // Reconectar
    _disconnectWebSocket();
    await Future.delayed(const Duration(milliseconds: 500));
    await _connectWebSocket();
    
    // Si estaba en streaming, reiniciar
    if (wasStreaming) {
      await Future.delayed(const Duration(milliseconds: 500));
      startStreaming();
    }
  }
  
  // Para diagnóstico
  Future<void> testCamera() async {
    if (cameraController == null) {
      print('❌ Cámara no inicializada');
      return;
    }
    
    try {
      final XFile testImage = await cameraController!.takePicture();
      print('✅ Cámara funciona correctamente. Foto guardada en: ${testImage.path}');
    } catch (e) {
      print('❌ Error probando cámara: $e');
    }
  }
}