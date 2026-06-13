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
        return Scaffold(
          body: Column(
            children: [
              // Barra superior con estado de conexión
              _buildConnectionBar(controller),
              
              // Selector de modelo
              _buildModelSelector(context, controller),
              
              // Vista de cámara
              Expanded(
                child: _buildCameraPreview(context, controller),
              ),
              
              // Resultados y métricas
              _buildResultsPanel(context, controller),
            ],
          ),
        );
      },
    );
  }

  Widget _buildConnectionBar(CarDetectorController controller) {
    return Obx(() => Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: controller.isConnected.value ? Colors.green[700] : Colors.red[700],
      child: Row(
        children: [
          Icon(
            controller.isConnected.value ? Icons.wifi : Icons.wifi_off,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              controller.connectionStatus.value,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
          if (!controller.isConnected.value)
            TextButton(
              onPressed: () => controller.reconnectWebSocket(),
              child: const Text(
                'Reconectar',
                style: TextStyle(color: Colors.white),
              ),
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Obx(() => Text(
              controller.fps.value,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            )),
          ),
        ],
      ),
    ));
  }

  Widget _buildModelSelector(BuildContext context, CarDetectorController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.model_training, size: 20),
          const SizedBox(width: 8),
          const Text('Modelo:'),
          const SizedBox(width: 8),
          Expanded(
            child: Obx(() => DropdownButton<String>(
              value: controller.selectedModel.value,
              isExpanded: true,
              underline: const SizedBox(),
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
        color: Colors.black,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 12),
              Text('Inicializando cámara...', style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
      );
    }

    return Container(
      color: Colors.black,
      child: CameraPreview(controller.cameraController!),
    );
  }

  Widget _buildResultsPanel(BuildContext context, CarDetectorController controller) {
    return Obx(() {
      if (controller.processedImage.value.isEmpty) {
        return Container(
          height: 120,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
          ),
          child: const Center(
            child: Text('Esperando detecciones...'),
          ),
        );
      }
      
      return Container(
        height: 280,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Imagen procesada
              Container(
                height: 120,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(7),
                  child: Image.memory(
                    base64Decode(controller.processedImage.value),
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              
              // Conteo de vehículos
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Vehículos detectados:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
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
              
              // Detecciones
              if (controller.detections.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text(
                  'Detecciones:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  children: controller.detections.map((det) {
                    return Chip(
                      label: Text('${det['label']}: ${(det['confidence'] * 100).toStringAsFixed(0)}%'),
                      avatar: const Icon(Icons.directions_car, size: 16),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      );
    });
  }
}