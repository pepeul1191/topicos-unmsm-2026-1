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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _getController();
  }

  void _getController() {
    try {
      if (Get.isRegistered<PlateReaderController>()) {
        controller = Get.find<PlateReaderController>();
      } else {
        // Fallback: crear el controlador si no existe
        controller = Get.put(PlateReaderController());
      }
    } catch (e) {
      debugPrint('Error obteniendo controlador: $e');
      controller = Get.put(PlateReaderController());
    }
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

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // No disposeamos el controller aquí porque HomePage lo maneja
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => SingleChildScrollView( // Añadido para evitar desbordamiento (Overflow) al mostrar mucha info
        child: Column(
          children: [
            const SizedBox(height: 8),
            
            // Vista de cámara
            _buildCameraPreview(),
            
            const SizedBox(height: 16),
            
            // Número de placa detectado
            _buildPlateNumber(),
            
            const SizedBox(height: 16),

            // NUEVO: Sección de información detallada del vehículo (Rails API)
            _buildCarDetails(),
            
            const SizedBox(height: 16),
            
            // Estado y métricas
            _buildStatusMetrics(),
            
            const SizedBox(height: 16),
            
            // Consejos
            _buildTips(),
            
            const SizedBox(height: 24),
            
            // Botón de reinicio
            _buildRestartButton(),
            
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildCarDetails() {
    final details = controller.carDetails.value;
    final error = controller.errorMessage.value;

    // CASO 1: Si hay un error explícito de que no se encontró la placa
    if (error.isNotEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.errorContainer.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.error.withOpacity(0.4),
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.no_accounts, color: Theme.of(context).colorScheme.error),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Vehículo no registrado',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                  ),
                  Text(
                    error, // Aquí se muestra el "La placa ABC-123 no se encuentra registrada" que viene de Rails
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onErrorContainer.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // CASO 2: Si no hay datos y tampoco hay error (estado inicial / esperando escaneo)
    if (details == null) {
      return const SizedBox.shrink();
    }

    // CASO 3: SUCCESS TRUE (Muestra la tarjeta con los datos del auto que ya tenías)
    final car = details.car;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  child: Icon(Icons.person, color: Theme.of(context).colorScheme.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(car.owner, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(
                        '${car.branch} ${car.model} • ${car.color} (${car.fabricated})',
                        style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          
          // ... (Tus ExpansionTiles de Infracciones, Reclamos y Revisiones se quedan exactamente igual)
          ExpansionTile(
            leading: Icon(Icons.gavel, color: details.infractions.isNotEmpty ? Colors.red : Colors.grey),
            title: Text('Infracciones (${details.infractions.length})'),
            children: details.infractions.isEmpty
                ? [const ListTile(title: Text('Sin infracciones registradas', style: TextStyle(fontSize: 13, color: Colors.grey)))]
                : details.infractions.map((inf) => ListTile(title: Text(inf.description, style: const TextStyle(fontSize: 13)), dense: true)).toList(),
          ),
          // ... etc
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
        // Sin fondo (transparente)
        color: Colors.transparent, 
        // Borde claro usando el esquema de colores del tema
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant, // Un gris/borde claro automático del tema
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          children: [
            Text(
              'PLACA DETECTADA',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                // Cambiado a un color oscuro o primario del tema para que contraste con el fondo claro
                color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            Obx(
              () => Text(
                controller.plateNumber.value,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  // Cambiado para que el texto de la placa sea legible sin el fondo azul
                  color: Theme.of(context).colorScheme.onSurface, 
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
    if (controller == null) {
      return const SizedBox.shrink();
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ElevatedButton.icon(
        onPressed: () => controller!.reconnectWebSocket(), // Usar reconnectWebSocket
        icon: const Icon(Icons.refresh, size: 18),
        label: const Text('Reconectar'),
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