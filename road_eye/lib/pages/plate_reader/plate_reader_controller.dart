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

class PlateReaderController extends GetxController {
  final CarService _carService = CarService();

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

  // Detalle del Carro
  final Rxn<CarDetails> carDetails = Rxn<CarDetails>();
  var errorMessage = ''.obs;
  
  // Control de estado
  bool _isDisposing = false;
  bool _isCapturing = false;
  String _lastProcessedPlate = '';
  
  // Configuración
  final String wsUrl = Constants.wsUrl;
  final int frameIntervalMs = 150; // YOLO en server.py procesa rápido (ideal ~6-7 FPS)
  
  @override
  void onInit() {
    super.onInit();
    _initCamera();
    _connectWebSocket();
    _startFpsCounter();
    
    // Escuchar cuando el auto es encontrado
    ever(carDetails, (CarDetails? details) {
      if (details != null) {
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
        status.value = '❌ No hay cámara disponible';
        return;
      }
      
      final camera = cameras.first;
      
      // Ajustamos la resolución a LOW o MEDIUM (suficiente para YOLO)
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
      status.value = '❌ Error de cámara';
      if (kDebugMode) {
        print('❌ Error inicializando cámara: $e');
      }
    }
  }
  
  void _startFrameCapture() {
    frameTimer?.cancel();
    // Subimos el intervalo a 300ms para darle tiempo al hardware de la cámara a cerrar la foto anterior
    frameTimer = Timer.periodic(
      const Duration(milliseconds: 300),
      (_) => _captureAndSendFrame(),
    );
  }
  
  Future<void> _captureAndSendFrame() async {
    if (_isDisposing || _isCapturing) return;

    if (cameraController == null || 
        !cameraController!.value.isInitialized || 
        !isConnected.value) {
      return;
    }

    _isCapturing = true;

    try {
      final startTime = DateTime.now();

      // 1. Tomar foto
      final XFile image = await cameraController!.takePicture();
      
      // 2. Leer bytes
      final bytes = await image.readAsBytes();
      final base64Image = base64Encode(bytes);

      // 3. Enviar al WebSocket
      if (webSocketChannel != null && !_isDisposing) {
        webSocketChannel!.sink.add(jsonEncode({
          'type': 'frame',
          'image': base64Image,
        }));
      }

      final endTime = DateTime.now();
      latency.value = '${endTime.difference(startTime).inMilliseconds} ms';
      frameCount++;

    } catch (e) {
      // Silenciar error habitual de toma de captura concurrente
      if (!e.toString().contains('Previous capture has not returned yet')) {
        if (kDebugMode) {
          print('⚠️ Error capturando frame: $e');
        }
      }
    } finally {
      _isCapturing = false;
    }
  }

  // ============= MÉTODOS DE WEBSOCKET Y RESPUESTA =============
  
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
          if (!_isDisposing) {
            status.value = '⚪ Desconectado';
            isConnected.value = false;
          }
        },
        onError: (error) {
          if (!_isDisposing) {
            status.value = '⚠️ Error de conexión';
            isConnected.value = false;
          }
        },
      );
      
      status.value = '✅ Conectado';
      isConnected.value = true;
      
    } catch (e) {
      if (!_isDisposing) {
        status.value = '❌ Error de conexión';
        isConnected.value = false;
      }
    }
  }
  
  void _handleWebSocketMessage(dynamic message) {
    try {
      final data = jsonDecode(message);

      // server.py responde con 'type': 'detection'
      if (data['type'] == 'detection') {
        if (data['plate'] != null && data['plate'].toString().isNotEmpty) {
          final String detectedPlate = data['plate'];
          plateNumber.value = detectedPlate;
          
          // Prevenir peticiones repetidas a la base de datos para la misma placa
          if (_lastProcessedPlate != detectedPlate && !_isDisposing) {
            _searchCarDetails(detectedPlate);
          }
        } else if (plateNumber.value != '———') {
          plateNumber.value = '🔍 Buscando placa...';
        }
        
        // Muestra de métricas recibidas del servidor YOLO
        if (data['process_time'] != null && kDebugMode) {
          print('⏱️ Server YOLO time: ${data['process_time']} ms | Conf: ${data['ocr_conf']}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error procesando mensaje del WebSocket: $e');
      }
    }
  }

  // ============= BÚSQUEDA Y SERVICIOS =============

  void _searchCarDetails(String numeroPlaca) async {
    if (_lastProcessedPlate == numeroPlaca) return;
    
    _lastProcessedPlate = numeroPlaca;
    errorMessage.value = '';
  
    GenericResponse<CarDetails> response = await _carService.fetchByPlate(numeroPlaca);
    
    if (response.success && response.data != null) {
      carDetails.value = response.data;
    } else {
      carDetails.value = null;
      errorMessage.value = response.message;
      
      // Dar un pequeño margen (2 segundos) antes de intentar buscar la misma placa nuevamente
      Future.delayed(const Duration(seconds: 2), () {
        if (!_isDisposing) {
          _lastProcessedPlate = '';
        }
      });
    }
  }

  // ============= MÉTODOS DE CIERRE Y RESETEO =============
  
  Future<void> _closeWebSocketAndCamera() async {
    if (_isDisposing) return;
    
    status.value = '✅ Placa encontrada';
    _isDisposing = true;
    
    frameTimer?.cancel();
    frameTimer = null;
    fpsTimer?.cancel();
    fpsTimer = null;
    
    if (webSocketChannel != null) {
      try {
        await webSocketChannel!.sink.close();
      } catch (_) {}
      webSocketChannel = null;
    }
    
    isConnected.value = false;
  }

  void _startFpsCounter() {
    fpsTimer?.cancel();
    fpsTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isDisposing) {
        fps.value = '$frameCount fps';
        frameCount = 0;
      }
    });
  }

  Future<void> reconnectWebSocket() async {
    if (_isDisposing) return;
    
    status.value = '🔄 Reconectando...';
    _lastProcessedPlate = '';
    carDetails.value = null;
    errorMessage.value = '';
    plateNumber.value = '———';
    
    if (webSocketChannel != null) {
      try {
        await webSocketChannel!.sink.close();
      } catch (_) {}
      webSocketChannel = null;
    }
    
    isConnected.value = false;
    _isDisposing = false;
    
    await Future.delayed(const Duration(milliseconds: 300));
    _connectWebSocket();
  }
  
  Future<void> resetAndRestart() async {
    _lastProcessedPlate = '';
    carDetails.value = null;
    errorMessage.value = '';
    plateNumber.value = '———';
    _isDisposing = false;
    
    _startFrameCapture();
    await reconnectWebSocket();
  }

  void _disposeResources() {
    frameTimer?.cancel();
    frameTimer = null;
    fpsTimer?.cancel();
    fpsTimer = null;
    
    if (webSocketChannel != null) {
      try {
        webSocketChannel!.sink.close();
      } catch (_) {}
      webSocketChannel = null;
    }
    
    if (cameraController != null) {
      try {
        cameraController!.dispose();
      } catch (_) {}
      cameraController = null;
    }
    
    isCameraReady.value = false;
    isConnected.value = false;
    status.value = '⚪ Desconectado';
    plateNumber.value = '———';
    fps.value = '0 fps';
    latency.value = '0 ms';
    frameCount = 0;
    _isCapturing = false;
  }
  
  Future<void> closeResources() async {
    _isDisposing = true;
    _disposeResources();
  }
}