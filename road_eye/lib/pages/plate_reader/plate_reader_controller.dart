// lib/pages/plate_reader/plate_reader_controller.dart
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:road_eye/configs/constants.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:image/image.dart' as img;

class PlateReaderController extends GetxController {
  // Cámara
  CameraController? cameraController;
  final isCameraReady = false.obs;
  
  // WebSocket
  WebSocketChannel? webSocketChannel;
  final isConnected = false.obs;
  final status = '⚪ Desconectado'.obs;
  
  // Detección
  final plateNumber = '———'.obs;
  
  // Métricas
  final fps = '0 fps'.obs;
  final latency = '0 ms'.obs;
  int frameCount = 0;
  DateTime lastFpsTime = DateTime.now();
  Timer? fpsTimer;
  Timer? frameTimer;
  
  // Configuración
  final String wsUrl = Constants.wsUrl; // Cambiar según IP del servidor
  final int frameIntervalMs = 100; // 10 fps
  
  @override
  void onInit() {
    super.onInit();
    _initCamera();
    _connectWebSocket();
    _startFpsCounter();
  }
  
  @override
  void onClose() {
    _disposeResources();
    super.onClose();
  }
  
  // ============= MÉTODOS DE CÁMARA =============
  
  Future<void> _initCamera() async {
    try {
      // Obtener la primera cámara disponible
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        status.value = '❌ No hay cámara';
        return;
      }
      
      final camera = cameras.first; // Usar cámara trasera
      
      cameraController = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      
      await cameraController!.initialize();
      isCameraReady.value = true;
      _startFrameCapture();
      
      if (kDebugMode) {
        print('✅ Cámara inicializada correctamente');
      }
    } catch (e) {
      status.value = '❌ Error cámara';
      if (kDebugMode) {
        print('❌ Error inicializando cámara: $e');
      }
    }
  }
  
  void _startFrameCapture() {
    frameTimer?.cancel();
    frameTimer = Timer.periodic(
      Duration(milliseconds: frameIntervalMs),
      (_) => _captureAndSendFrame(),
    );
  }
  
  Future<void> _captureAndSendFrame() async {
    if (cameraController == null || 
        !cameraController!.value.isInitialized || 
        !isConnected.value) {
      return;
    }
    
    try {
      final startTime = DateTime.now();
      
      // Capturar imagen
      final XFile image = await cameraController!.takePicture();
      final bytes = await image.readAsBytes();
      
      // Comprimir imagen
      final compressedBytes = await _compressImage(bytes);
      
      // Convertir a base64
      final base64Image = base64Encode(compressedBytes);
      
      // Enviar por WebSocket
      if (webSocketChannel != null) {
        webSocketChannel!.sink.add(jsonEncode({
          'type': 'frame',
          'image': base64Image,
        }));
      }
      
      // Actualizar latencia (tiempo de captura + compresión)
      final endTime = DateTime.now();
      final processingTime = endTime.difference(startTime).inMilliseconds;
      latency.value = '$processingTime ms';
      
      // Actualizar contador de frames para FPS
      frameCount++;
      
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error capturando frame: $e');
      }
    }
  }
  
  Future<Uint8List> _compressImage(Uint8List bytes) async {
    try {
      img.Image? original = img.decodeImage(bytes);
      if (original == null) return bytes;
      
      // Redimensionar a 480px de ancho
      final resized = img.copyResize(original, width: 480);
      
      // Codificar a JPEG con 70% calidad
      final compressed = img.encodeJpg(resized, quality: 70);
      
      return Uint8List.fromList(compressed);
    } catch (e) {
      return bytes;
    }
  }
  
  // ============= MÉTODOS DE WEBSOCKET =============
  
  void _connectWebSocket() {
    try {
      webSocketChannel = WebSocketChannel.connect(Uri.parse(wsUrl));
      
      webSocketChannel!.stream.listen(
        (message) {
          _handleWebSocketMessage(message);
        },
        onDone: () {
          status.value = '⚪ Desconectado';
          isConnected.value = false;
          
          // Intentar reconectar después de 2 segundos
          Future.delayed(const Duration(seconds: 2), () {
            if (Get.isRegistered<PlateReaderController>()) {
              _connectWebSocket();
            }
          });
        },
        onError: (error) {
          status.value = '⚠️ Error WS';
          isConnected.value = false;
          if (kDebugMode) {
            print('❌ WebSocket error: $error');
          }
        },
      );
      
      status.value = '✅ Conectado';
      isConnected.value = true;
      
      if (kDebugMode) {
        print('✅ WebSocket conectado a $wsUrl');
      }
    } catch (e) {
      status.value = '❌ Error conexión';
      if (kDebugMode) {
        print('❌ Error conectando WebSocket: $e');
      }
    }
  }
  
  void _handleWebSocketMessage(dynamic message) {
    try {
      final data = jsonDecode(message);
      
      if (data['type'] == 'detection') {
        // Actualizar número de placa
        if (data['plate'] != null && data['plate'].toString().isNotEmpty) {
          plateNumber.value = data['plate'];
        } else if (plateNumber.value != '———') {
          plateNumber.value = '🔍 Buscando...';
        }
        
        // Actualizar latencia del servidor si viene
        if (data['process_time'] != null) {
          // La latencia ya la calculamos en el cliente, solo mostramos la del servidor
          final serverLatency = data['process_time'];
          if (kDebugMode) {
            print('Server processing time: ${serverLatency}ms');
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error parseando mensaje: $e');
      }
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
  
  // ============= UTILIDADES =============
  
  void _disposeResources() {
    frameTimer?.cancel();
    fpsTimer?.cancel();
    
    if (cameraController != null) {
      cameraController!.dispose();
    }
    
    if (webSocketChannel != null) {
      webSocketChannel!.sink.close();
    }
  }
  
  Future<void> restartCamera() async {
    status.value = '🔄 Reiniciando...';
    _disposeResources();
    await _initCamera();
    _connectWebSocket();
  }
}