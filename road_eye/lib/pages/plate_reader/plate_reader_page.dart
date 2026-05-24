// lib/pages/plate_reader/plate_reader_page.dart
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'plate_reader_controller.dart';

class PlateReaderPage extends StatefulWidget {
  const PlateReaderPage({super.key});

  @override
  State<PlateReaderPage> createState() => _PlateReaderPageState();
}

class _PlateReaderPageState extends State<PlateReaderPage> with WidgetsBindingObserver {
  late PlateReaderController controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeController();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Reanudar cámara cuando la app vuelve a primer plano
      if (controller.isCameraReady.value && controller.cameraController != null) {
        controller.cameraController!.resumePreview();
      }
    } else if (state == AppLifecycleState.paused) {
      // Pausar cámara cuando la app pasa a segundo plano
      if (controller.isCameraReady.value && controller.cameraController != null) {
        controller.cameraController!.pausePreview();
      }
    }
  }

  Future<void> _initializeController() async {
    try {
      // Verificar si el controlador ya existe en GetX
      if (Get.isRegistered<PlateReaderController>()) {
        controller = Get.find<PlateReaderController>();
      } else {
        // Si no existe, crear el controlador (sin parámetros)
        controller = Get.put(PlateReaderController());
        
        // Pequeña espera para que el controlador se inicialice
        await Future.delayed(const Duration(milliseconds: 500));
      }
      
      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      debugPrint('Error inicializando controlador: $e');
      setState(() {
        _isInitialized = true;
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // No disposeamos el controller aquí porque podría necesitarse al volver a la pestaña
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Obx(
      () => Column(
        children: [
          const SizedBox(height: 8),
          
          // Vista de cámara
          _buildCameraPreview(),
          
          const SizedBox(height: 16),
          
          // Número de placa detectado
          _buildPlateNumber(),
          
          const SizedBox(height: 16),
          
          // Estado y métricas
          _buildStatusMetrics(),
          
          const SizedBox(height: 16),
          
          // Consejos
          _buildTips(),
          
          const Spacer(),
          
          // Botón de reinicio
          _buildRestartButton(),
          
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildCameraPreview() {
    if (!controller.isCameraReady.value ||
        controller.cameraController == null ||
        !controller.cameraController!.value.isInitialized) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        height: 250,
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 12),
              Text(
                'Inicializando cámara...',
                style: TextStyle(color: Colors.white54),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: AspectRatio(
          aspectRatio: 4 / 3,
          child: controller.cameraController != null && controller.cameraController!.value.isInitialized
              ? CameraPreview(controller.cameraController!)
              : Container(
                  color: Colors.black,
                  child: const Center(
                    child: Text(
                      'Cámara no disponible',
                      style: TextStyle(color: Colors.white54),
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildPlateNumber() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primaryContainer,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Column(
          children: [
            const Text(
              'PLACA DETECTADA',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white70,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            Obx(
              () => Text(
                controller.plateNumber.value,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusMetrics() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Estado de conexión
          _buildMetricChip(
            icon: Icons.wifi,
            label: controller.status.value,
            color: controller.status.value.contains('Conectado')
                ? Colors.green
                : controller.status.value.contains('Error')
                    ? Colors.red
                    : Colors.grey,
          ),
          
          // FPS
          _buildMetricChip(
            icon: Icons.speed,
            label: controller.fps.value,
            color: Colors.blue,
          ),
          
          // Latencia
          _buildMetricChip(
            icon: Icons.timer,
            label: controller.latency.value,
            color: Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildMetricChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTips() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(Icons.lightbulb_outline, color: Colors.amber[700], size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Consejos para mejor rendimiento',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Buena iluminación • 20-30cm de distancia • Fondo claro',
                  style: TextStyle(
                    fontSize: 10,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRestartButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ElevatedButton.icon(
        onPressed: () => controller.restartCamera(),
        icon: const Icon(Icons.refresh, size: 18),
        label: const Text('Reiniciar conexión'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          foregroundColor: Theme.of(context).colorScheme.onSurface,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}