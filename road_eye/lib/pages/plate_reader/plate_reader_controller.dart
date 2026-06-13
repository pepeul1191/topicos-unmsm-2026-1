// lib/pages/plate_reader/plate_reader_controller.dart
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:road_eye/configs/constants.dart';
import 'package:road_eye/configs/generic_response.dart';
import 'package:road_eye/models/car_details.dart';
import 'package:road_eye/services/car_service.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:image/image.dart' as img;

class PlateReaderController extends GetxController {
  CarService _carService = CarService();

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
  Timer? fpsTimer;
  Timer? frameTimer;

  // Detalle del Carros
  final Rxn<CarDetails> carDetails = Rxn<CarDetails>();
  var errorMessage = ''.obs; // Variable reactiva para el error
  
  // Control de estado
  bool _isDisposing = false;
  bool _isCapturing = false; // Previene capturas simultáneas
  String _lastProcessedPlate = ''; // Para evitar procesar la misma placa múltiples veces
  
  // Configuración
  final String wsUrl = Constants.wsUrl;
  final int frameIntervalMs = 200; // Cambiado de 100 a 200ms (5 fps)
  
  @override
  void onInit() {
    super.onInit();
    _initCamera();
    _connectWebSocket();
    _startFpsCounter();
    
    // Listener para cuando se obtienen los detalles del auto
    ever(carDetails, (CarDetails? details) {
      if (details != null) {
        // Si se obtuvieron los detalles del auto, cerrar WebSocket
        _closeWebSocketAndCamera();
      }
    });
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
        ResolutionPreset.low,
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
        //print('❌ Error inicializando cámara: $e');
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
    // No capturar si está cerrando o ya hay una captura en curso
    if (_isDisposing || _isCapturing) return;
    
    if (cameraController == null || 
        !cameraController!.value.isInitialized || 
        !isConnected.value) {
      return;
    }
    
    _isCapturing = true;
    
    try {
      final startTime = DateTime.now();
      
      // Capturar imagen
      final XFile image = await cameraController!.takePicture();
      final bytes = await image.readAsBytes();
      
      // Comprimir imagen
      final compressedBytes = await _compressImage(bytes);
      final base64Image = base64Encode(compressedBytes);
      
      // Enviar por WebSocket
      if (webSocketChannel != null && !_isDisposing) {
        webSocketChannel!.sink.add(jsonEncode({
          'type': 'frame',
          'image': base64Image,
        }));
      }
      
      // Actualizar latencia
      final endTime = DateTime.now();
      final processingTime = endTime.difference(startTime).inMilliseconds;
      latency.value = '$processingTime ms';
      
      // Actualizar contador de frames para FPS
      frameCount++;
      
    } catch (e) {
      if (!_isDisposing && !e.toString().contains('Previous capture has not returned yet')) {
        if (kDebugMode) {
          print('❌ Error capturando frame: $e');
        }
      }
    } finally {
      _isCapturing = false;
    }
  }
  
  Future<Uint8List> _compressImage(Uint8List bytes) async {
    try {
      img.Image? original = img.decodeImage(bytes);
      if (original == null) return bytes;
      
      final resized = img.copyResize(original, width: 320);
      final compressed = img.encodeJpg(resized, quality: 60);
      
      return Uint8List.fromList(compressed);
    } catch (e) {
      return bytes;
    }
  }

  // ============= MÉTODO PARA CERRAR WEBSOCKET Y CÁMARA =============
  
  Future<void> _closeWebSocketAndCamera() async {
    if (_isDisposing) return;
    
    if (kDebugMode) {
      print('🔒 Cerrando WebSocket y cámara - Auto detectado correctamente');
    }
    
    status.value = '✅ Auto detectado';
    _isDisposing = true;
    
    // Detener timers de captura
    frameTimer?.cancel();
    frameTimer = null;
    
    fpsTimer?.cancel();
    fpsTimer = null;
    
    // Cerrar WebSocket
    if (webSocketChannel != null) {
      try {
        await webSocketChannel!.sink.close();
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
    
    isConnected.value = false;
    
    // Nota: No disposeamos la cámara para poder ver el último frame
    // Solo cerramos el WebSocket
    
    if (kDebugMode) {
      print('✅ Recursos cerrados exitosamente');
    }
  }

  // ============= RAILS ==============

  void _searchCarDetails(String numeroPlaca) async {
    // Evitar procesar la misma placa múltiples veces
    if (_lastProcessedPlate == numeroPlaca) {
      return;
    }
    
    _lastProcessedPlate = numeroPlaca;
    errorMessage.value = '';
  
    GenericResponse<CarDetails> response = await _carService.fetchByPlate(numeroPlaca);
    
    if (response.success && response.data != null) {
      carDetails.value = response.data;
      // El ever() listener se encargará de cerrar el WebSocket automáticamente
    } else {
      carDetails.value = null;
      errorMessage.value = response.message;
      // Resetear para permitir reintentar con otra placa
      _lastProcessedPlate = '';
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
          }
        },
        onError: (error) {
          if (kDebugMode && !_isDisposing) {
            //print('❌ WebSocket error: $error');
          }
          
          if (!_isDisposing) {
            status.value = '⚠️ Error de conexión';
            isConnected.value = false;
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
        //print('❌ Error conectando WebSocket: $e');
      }
      
      if (!_isDisposing) {
        status.value = '❌ Error de conexión';
        isConnected.value = false;
      }
    }
  }
  
  void _handleWebSocketMessage(dynamic message) {
    try {
      final data = jsonDecode(message);

      if (kDebugMode) {
        print('📨 Mensaje recibido: $data');
      }
      
      if (data['type'] == 'detection') {
        if (data['plate'] != null && data['plate'].toString().isNotEmpty) {
          final detectedPlate = data['plate'];
          plateNumber.value = detectedPlate;
          
          // Solo buscar si aún no hemos procesado esta placa y el WebSocket está activo
          if (_lastProcessedPlate != detectedPlate && !_isDisposing) {
            _searchCarDetails(detectedPlate);
          }
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
        //print('❌ Error parseando mensaje: $e');
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
    
    // Resetear estado
    _lastProcessedPlate = '';
    carDetails.value = null;
    errorMessage.value = '';
    plateNumber.value = '———';
    
    // Cerrar conexión existente
    if (webSocketChannel != null) {
      try {
        await webSocketChannel!.sink.close();
      } catch (e) {
        if (kDebugMode) {
          //print('❌ Error cerrando WebSocket: $e');
        }
      }
      webSocketChannel = null;
    }
    
    isConnected.value = false;
    _isDisposing = false;
    
    // Pequeña pausa antes de reconectar
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Intentar nueva conexión
    _connectWebSocket();
  }
  
  // Método para reiniciar el escaneo (después de ver los detalles)
  Future<void> resetAndRestart() async {
    if (kDebugMode) {
      print('🔄 Reiniciando escaneo...');
    }
    
    // Resetear estados
    _lastProcessedPlate = '';
    carDetails.value = null;
    errorMessage.value = '';
    plateNumber.value = '———';
    _isDisposing = false;
    
    // Reconectar WebSocket
    await reconnectWebSocket();
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
          //print('❌ Error cerrando WebSocket: $e');
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
          //print('❌ Error liberando cámara: $e');
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
    _isCapturing = false;
    
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