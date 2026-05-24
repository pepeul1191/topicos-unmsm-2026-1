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
  
  // Control de estado
  bool _isDisposing = false;
  
  // Configuración
  final String wsUrl = Constants.wsUrl;
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
    _isDisposing = true;
    _disposeResources();
    super.onClose();
  }
  
  // ============= MÉTODOS DE CÁMARA =============
  
  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        status.value = '❌ No hay cámara';
        return;
      }
      
      final camera = cameras.first;
      
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
    // No capturar si está cerrando
    if (_isDisposing) return;
    
    if (cameraController == null || 
        !cameraController!.value.isInitialized || 
        !isConnected.value) {
      return;
    }
    
    try {
      final startTime = DateTime.now();
      
      final XFile image = await cameraController!.takePicture();
      final bytes = await image.readAsBytes();
      final compressedBytes = await _compressImage(bytes);
      final base64Image = base64Encode(compressedBytes);
      
      if (webSocketChannel != null && !_isDisposing) {
        webSocketChannel!.sink.add(jsonEncode({
          'type': 'frame',
          'image': base64Image,
        }));
      }
      
      final endTime = DateTime.now();
      final processingTime = endTime.difference(startTime).inMilliseconds;
      latency.value = '$processingTime ms';
      
      frameCount++;
      
    } catch (e) {
      if (kDebugMode && !_isDisposing) {
        print('❌ Error capturando frame: $e');
      }
    }
  }
  
  Future<Uint8List> _compressImage(Uint8List bytes) async {
    try {
      img.Image? original = img.decodeImage(bytes);
      if (original == null) return bytes;
      
      final resized = img.copyResize(original, width: 480);
      final compressed = img.encodeJpg(resized, quality: 70);
      
      return Uint8List.fromList(compressed);
    } catch (e) {
      return bytes;
    }
  }
  
  // ============= MÉTODOS DE WEBSOCKET =============
  
  void _connectWebSocket() {
    if (_isDisposing) return;
    
    try {
      if (kDebugMode) {
        print('🔄 Conectando WebSocket a $wsUrl');
      }
      
      webSocketChannel = WebSocketChannel.connect(Uri.parse(wsUrl));
      
      webSocketChannel!.stream.listen(
        (message) {
          if (!_isDisposing) {
            _handleWebSocketMessage(message);
          }
        },
        onDone: () {
          if (kDebugMode && !_isDisposing) {
            print('🔌 WebSocket desconectado');
          }
          
          if (!_isDisposing) {
            status.value = '⚪ Desconectado';
            isConnected.value = false;
            // NO reconectar automáticamente - el usuario debe presionar el botón
          }
        },
        onError: (error) {
          if (kDebugMode && !_isDisposing) {
            print('❌ WebSocket error: $error');
          }
          
          if (!_isDisposing) {
            status.value = '⚠️ Error de conexión';
            isConnected.value = false;
            // NO reconectar automáticamente - el usuario debe presionar el botón
          }
        },
      );
      
      status.value = '✅ Conectado';
      isConnected.value = true;
      
      if (kDebugMode) {
        print('✅ WebSocket conectado a $wsUrl');
      }
    } catch (e) {
      if (kDebugMode && !_isDisposing) {
        print('❌ Error conectando WebSocket: $e');
      }
      
      if (!_isDisposing) {
        status.value = '❌ Error de conexión';
        isConnected.value = false;
        // NO reconectar automáticamente - el usuario debe presionar el botón
      }
    }
  }
  
  void _handleWebSocketMessage(dynamic message) {
    try {
      final data = jsonDecode(message);
      
      if (data['type'] == 'detection') {
        if (data['plate'] != null && data['plate'].toString().isNotEmpty) {
          plateNumber.value = data['plate'];
        } else if (plateNumber.value != '———') {
          plateNumber.value = '🔍 Buscando...';
        }
        
        if (data['process_time'] != null && kDebugMode) {
          final serverLatency = data['process_time'];
          print('Server processing time: ${serverLatency}ms');
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
      if (!_isDisposing) {
        fps.value = '$frameCount fps';
        frameCount = 0;
      }
    });
  }
  
  // ============= MÉTODO PARA RECONECTAR MANUALMENTE =============
  
  Future<void> reconnectWebSocket() async {
    if (_isDisposing) return;
    
    if (kDebugMode) {
      print('🔄 Reconectando WebSocket manualmente...');
    }
    
    status.value = '🔄 Reconectando...';
    
    // Cerrar conexión existente
    if (webSocketChannel != null) {
      try {
        await webSocketChannel!.sink.close();
      } catch (e) {
        if (kDebugMode) {
          print('❌ Error cerrando WebSocket: $e');
        }
      }
      webSocketChannel = null;
    }
    
    isConnected.value = false;
    
    // Pequeña pausa antes de reconectar
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Intentar nueva conexión
    _connectWebSocket();
  }
  
  // ============= UTILIDADES =============
  
  void _disposeResources() {
    if (kDebugMode) {
      print('🔌 Cerrando recursos del lector de placas...');
    }
    
    // Detener timers
    frameTimer?.cancel();
    frameTimer = null;
    
    fpsTimer?.cancel();
    fpsTimer = null;
    
    // Cerrar WebSocket
    if (webSocketChannel != null) {
      try {
        webSocketChannel!.sink.close();
        if (kDebugMode) {
          print('✅ WebSocket cerrado');
        }
      } catch (e) {
        if (kDebugMode) {
          print('❌ Error cerrando WebSocket: $e');
        }
      }
      webSocketChannel = null;
    }
    
    // Dispose de la cámara
    if (cameraController != null) {
      try {
        cameraController!.dispose();
        if (kDebugMode) {
          print('✅ Cámara liberada');
        }
      } catch (e) {
        if (kDebugMode) {
          print('❌ Error liberando cámara: $e');
        }
      }
      cameraController = null;
    }
    
    // Resetear estados
    isCameraReady.value = false;
    isConnected.value = false;
    status.value = '⚪ Desconectado';
    plateNumber.value = '———';
    fps.value = '0 fps';
    latency.value = '0 ms';
    frameCount = 0;
    
    if (kDebugMode) {
      print('✅ Recursos cerrados correctamente');
    }
  }
  
  Future<void> restartCamera() async {
    if (_isDisposing) return;
    
    status.value = '🔄 Reiniciando...';
    _disposeResources();
    _isDisposing = false;
    await _initCamera();
    _connectWebSocket();
  }
  
  Future<void> closeResources() async {
    _isDisposing = true;
    _disposeResources();
  }
}