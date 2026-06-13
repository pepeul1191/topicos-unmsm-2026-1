// lib/pages/car_detector/car_detector_page.dart
import 'dart:convert';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'car_detector_controller.dart';

class CarDetectorPage extends StatelessWidget {
  const CarDetectorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<CarDetectorController>(
      init: CarDetectorController(),
      builder: (controller) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Selector de modelo
              _buildModelSelector(context, controller),
              const SizedBox(height: 16),
              
              // Vista de cámara
              _buildCameraPreview(context, controller),
              const SizedBox(height: 16),
              
              // Resultados
              _buildResults(context, controller),
              const SizedBox(height: 16),
              
              // Métricas
              _buildMetrics(context, controller),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModelSelector(BuildContext context, CarDetectorController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.model_training),
          const SizedBox(width: 12),
          const Text('Modelo:'),
          const SizedBox(width: 12),
          Expanded(
            child: Obx(() => DropdownButton<String>(
              value: controller.selectedModel.value,
              isExpanded: true,
              items: controller.models.map((model) {
                return DropdownMenuItem(
                  value: model['value'],
                  child: Text(model['label']!),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  controller.updateModel(value);
                }
              },
            )),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraPreview(BuildContext context, CarDetectorController controller) {
    if (!controller.isCameraReady.value) {
      return Container(
        height: 300,
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
              Text('Inicializando cámara...'),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.primary, width: 2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: AspectRatio(
          aspectRatio: 4 / 3,
          child: CameraPreview(controller.cameraController!),
        ),
      ),
    );
  }

  Widget _buildResults(BuildContext context, CarDetectorController controller) {
    return Obx(() {
      if (controller.processedImage.value.isNotEmpty) {
        return Column(
          children: [
            // Imagen procesada
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green, width: 1),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.memory(
                  base64Decode(controller.processedImage.value),
                  height: 200,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 12),
            
            // Conteo de vehículos
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.directions_car, color: Colors.blue),
                  const SizedBox(width: 12),
                  Text(
                    'Vehículos detectados:',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${controller.vehiclesCount.value}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
            
            // Lista de detecciones
            if (controller.detections.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Detecciones:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      ...controller.detections.map((det) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            Icon(Icons.circle, size: 8, color: Colors.green),
                            const SizedBox(width: 8),
                            Text('${det['label']}: ${(det['confidence'] * 100).toStringAsFixed(1)}%'),
                          ],
                        ),
                      )).toList(),
                    ],
                  ),
                ),
              ),
          ],
        );
      }
      
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Column(
          children: [
            Icon(Icons.search, size: 48, color: Colors.grey),
            SizedBox(height: 12),
            Text('Apunte la cámara a los vehículos'),
            SizedBox(height: 8),
            Text(
              'Las detecciones aparecerán aquí',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildMetrics(BuildContext context, CarDetectorController controller) {
    return Obx(() => Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.speed, size: 16),
              const SizedBox(width: 4),
              Text(controller.fps.value),
            ],
          ),
          Row(
            children: [
              Icon(
                controller.isDetecting.value ? Icons.sync : Icons.check_circle,
                size: 16,
                color: controller.isDetecting.value ? Colors.orange : Colors.green,
              ),
              const SizedBox(width: 4),
              Text(controller.isDetecting.value ? 'Detectando...' : 'Listo'),
            ],
          ),
        ],
      ),
    ));
  }
}