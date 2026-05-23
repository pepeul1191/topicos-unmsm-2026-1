import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:image/image.dart' as img;

class PlateController extends GetxController {
  final CameraDescription camera;
  
  // Controladores
  CameraController? cameraController;
  WebSocketChannel? webSocketChannel;
  Timer? frameTimer;
  
  // Variables observables
  final plateNumber = '———'.obs;
  final status = '⚪ Desconectado'.obs;
  final fps = '0 fps'.obs;
  final latency = '0 ms'.obs;
  final isConnected = false.obs;
  final isCameraReady = false.obs;
  
  // Variables internas
  int frameCount = 0;
  DateTime lastFpsTime = DateTime.now();
  Timer? fpsTimer;
  
  PlateController({required this.camera});
  
  @override
  void onInit() {
    super.onInit();
    initCamera();
    connectWebSocket();
    startFpsCounter();
  }
  
  @override
  void onClose() {
    disposeResources();
    super.onClose();
  }
  
  // Inicializar cámara
  Future<void> initCamera() async {
    try {
      cameraController = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      
      await cameraController!.initialize();
      isCameraReady.value = true;
      
      // Iniciar captura de frames
      startFrameCapture();
      
      if (kDebugMode) {
        print('Cámara inicializada correctamente');
      }
    } catch (e) {
      status.value = '❌ Error cámara';
      if (kDebugMode) {
        print('Error inicializando cámara: $e');
      }
    }
  }
  
  // Iniciar captura de frames
  void startFrameCapture() {
    frameTimer?.cancel();
    frameTimer = Timer.periodic(
      const Duration(milliseconds: 100), // 10 fps
      (timer) => captureAndSendFrame(),
    );
  }
  
  // Capturar y enviar frame
  Future<void> captureAndSendFrame() async {
    if (cameraController == null || 
        !cameraController!.value.isInitialized || 
        !isConnected.value) {
      return;
    }
    
    try {
      // Capturar imagen
      final XFile image = await cameraController!.takePicture();
      final bytes = await image.readAsBytes();
      
      // Comprimir imagen
      final compressedBytes = await compressImage(bytes);
      
      // Convertir a base64
      final base64Image = base64Encode(compressedBytes);
      
      // Enviar por WebSocket
      if (webSocketChannel != null) {
        webSocketChannel!.sink.add(jsonEncode({
          'type': 'frame',
          'image': base64Image,
        }));
      }
      
      // Actualizar contador de frames
      frameCount++;
      
    } catch (e) {
      if (kDebugMode) {
        print('Error capturando frame: $e');
      }
    }
  }
  
  // Comprimir imagen
  Future<Uint8List> compressImage(Uint8List bytes) async {
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
  
  // Conectar WebSocket
  void connectWebSocket() {
    final wsUrl = 'ws://192.168.1.23:8765';
    
    try {
      webSocketChannel = WebSocketChannel.connect(Uri.parse(wsUrl));
      
      webSocketChannel!.stream.listen(
        (message) {
          handleWebSocketMessage(message);
        },
        onDone: () {
          status.value = '⚪ Desconectado';
          isConnected.value = false;
          
          // Intentar reconectar después de 2 segundos
          Future.delayed(const Duration(seconds: 2), () {
            if (Get.isRegistered<PlateController>()) {
              connectWebSocket();
            }
          });
        },
        onError: (error) {
          status.value = '⚠️ Error WS';
          isConnected.value = false;
          if (kDebugMode) {
            print('WebSocket error: $error');
          }
        },
      );
      
      status.value = '✅ Conectado';
      isConnected.value = true;
      
      if (kDebugMode) {
        print('WebSocket conectado a $wsUrl');
      }
    } catch (e) {
      status.value = '❌ Error conexión';
      if (kDebugMode) {
        print('Error conectando WebSocket: $e');
      }
    }
  }
  
  // Manejar mensajes del WebSocket
  void handleWebSocketMessage(dynamic message) {
    try {
      final data = jsonDecode(message);
      
      if (data['type'] == 'detection') {
        // Actualizar número de placa
        if (data['plate'] != null) {
          plateNumber.value = data['plate'];
        } else if (data['plate'] == null && plateNumber.value != '———') {
          plateNumber.value = '🔍 Buscando...';
        }
        
        // Actualizar latencia
        if (data['process_time'] != null) {
          latency.value = '⚡ ${data['process_time']} ms';
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error parseando mensaje: $e');
      }
    }
  }
  
  // Contador de FPS
  void startFpsCounter() {
    fpsTimer?.cancel();
    fpsTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      fps.value = '📊 $frameCount fps';
      frameCount = 0;
    });
  }
  
  // Liberar recursos
  void disposeResources() {
    frameTimer?.cancel();
    fpsTimer?.cancel();
    
    if (cameraController != null) {
      cameraController!.dispose();
    }
    
    if (webSocketChannel != null) {
      webSocketChannel!.sink.close();
    }
  }
  
  // Método para reiniciar cámara
  Future<void> restartCamera() async {
    disposeResources();
    await initCamera();
    connectWebSocket();
  }
}