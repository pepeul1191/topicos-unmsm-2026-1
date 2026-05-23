import 'package:camera/camera.dart';  // ← DEBE SER LA PRIMERA LÍNEA
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/plate_controller.dart';

class CameraView extends StatelessWidget {
  const CameraView({super.key});
  
  @override
  Widget build(BuildContext context) {
    final controller = Get.find<PlateController>();
    
    return Scaffold(
      body: SafeArea(
        child: Obx(
          () => Column(
            children: [
              // Header
              _buildHeader(),
              
              const SizedBox(height: 16),
              
              // Vista de cámara
              _buildCameraPreview(controller),
              
              const SizedBox(height: 16),
              
              // Número de placa
              _buildPlateNumber(controller),
              
              const SizedBox(height: 16),
              
              // Estado y métricas
              _buildStatusMetrics(controller),
              
              const SizedBox(height: 16),
              
              // Consejos
              _buildTips(),
              
              const Spacer(),
              
              // Botón de reinicio
              _buildRestartButton(controller),
              
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text(
            '🇵🇪 Lector de Placas',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Modo rápido | Sin lag',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCameraPreview(PlateController controller) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade800),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: AspectRatio(
          aspectRatio: 4 / 3,
          child: controller.isCameraReady.value &&
                  controller.cameraController != null &&
                  controller.cameraController!.value.isInitialized
              ? CameraPreview(controller.cameraController!)  // ← Aquí usa CameraPreview
              : Container(
                  color: Colors.black,
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFFe94560),
                    ),
                  ),
                ),
        ),
      ),
    );
  }
  
  Widget _buildPlateNumber(PlateController controller) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade800),
      ),
      child: Center(
        child: Obx(
          () => Text(
            controller.plateNumber.value,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFFe94560),
              letterSpacing: 2,
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildStatusMetrics(PlateController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Obx(
            () => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey.shade900,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Icon(
                    controller.status.value.contains('Conectado')
                        ? Icons.check_circle
                        : controller.status.value.contains('Error')
                        ? Icons.error
                        : Icons.circle_outlined,
                    size: 12,
                    color: controller.status.value.contains('Conectado')
                        ? Colors.green
                        : controller.status.value.contains('Error')
                        ? Colors.red
                        : Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    controller.status.value,
                    style: const TextStyle(fontSize: 11),
                  ),
                ],
              ),
            ),
          ),
          
          Obx(
            () => Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFe94560),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                controller.fps.value,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          
          Obx(
            () => Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFe94560),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                controller.latency.value,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTips() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Icon(Icons.lightbulb_outline, color: Colors.amber, size: 20),
          const SizedBox(height: 4),
          const Text(
            '💡 Consejos para mejor rendimiento:',
            style: TextStyle(fontSize: 11, color: Colors.amber),
          ),
          const SizedBox(height: 2),
          Text(
            '• Buena iluminación • 20-30cm de distancia • Fondo claro',
            style: TextStyle(fontSize: 10, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  Widget _buildRestartButton(PlateController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ElevatedButton.icon(
        onPressed: () => controller.restartCamera(),
        icon: const Icon(Icons.refresh, size: 18),
        label: const Text('Reiniciar conexión'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey.shade800,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}