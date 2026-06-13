// lib/pages/car_detector/car_detector_page.dart - Versión sin cámara local
import 'dart:convert';
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
              // Barra de control
              _buildControlBar(controller),
              
              // Selector de modelo
              _buildModelSelector(context, controller),
              
              // SOLO la imagen procesada del servidor (sin cámara local)
              Expanded(
                child: _buildProcessedImage(controller),
              ),
              
              // Resultados
              _buildResultsPanel(context, controller),
            ],
          ),
        );
      },
    );
  }

  Widget _buildControlBar(CarDetectorController controller) {
    return Obx(() => Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.black87,
      child: Row(
        children: [
          Icon(
            controller.isStreaming.value ? Icons.visibility : Icons.visibility_off,
            color: controller.isStreaming.value ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              controller.isStreaming.value 
                  ? 'Streaming activo - Procesando con YOLO'
                  : 'Streaming detenido',
              style: const TextStyle(color: Colors.white),
            ),
          ),
          if (!controller.isStreaming.value)
            ElevatedButton(
              onPressed: controller.startStreaming,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('Iniciar Streaming'),
            ),
          if (controller.isStreaming.value)
            ElevatedButton(
              onPressed: controller.stopStreaming,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Detener Streaming'),
            ),
        ],
      ),
    ));
  }

  Widget _buildModelSelector(BuildContext context, CarDetectorController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.grey[900],
      child: Row(
        children: [
          const Icon(Icons.model_training, size: 20, color: Colors.white70),
          const SizedBox(width: 8),
          const Text('Modelo YOLO:', style: TextStyle(color: Colors.white70)),
          const SizedBox(width: 8),
          Expanded(
            child: Obx(() => DropdownButton<String>(
              value: controller.selectedModel.value,
              isExpanded: true,
              dropdownColor: Colors.grey[800],
              underline: const SizedBox(),
              style: const TextStyle(color: Colors.white),
              items: controller.models.map((model) {
                return DropdownMenuItem(
                  value: model['value'],
                  child: Text(model['label']!),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) controller.updateModel(value);
              },
            )),
          ),
        ],
      ),
    );
  }

  Widget _buildProcessedImage(CarDetectorController controller) {
    return Obx(() {
      // Mostrar imagen procesada del servidor
      if (controller.processedImage.value.isNotEmpty) {
        return Container(
          color: Colors.black,
          child: Image.memory(
            base64Decode(controller.processedImage.value),
            fit: BoxFit.contain,
            width: double.infinity,
          ),
        );
      }
      
      // Estado de carga
      if (controller.isStreaming.value) {
        return Container(
          color: Colors.black,
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Procesando video...', style: TextStyle(color: Colors.white)),
                SizedBox(height: 8),
                Text('Los resultados aparecerán aquí', style: TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        );
      }
      
      // Estado inicial
      return Container(
        color: Colors.black,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.play_circle, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text('Presione "Iniciar Streaming"', style: TextStyle(color: Colors.white)),
              SizedBox(height: 8),
              Text('La imagen procesada se mostrará aquí', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildResultsPanel(BuildContext context, CarDetectorController controller) {
    return Obx(() {
      if (controller.vehiclesCount.value == 0 && !controller.isStreaming.value) {
        return Container(
          height: 80,
          color: Colors.grey[900],
        );
      }
      
      return Container(
        height: 80,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        color: Colors.grey[900],
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('VEHÍCULOS', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  Text(
                    '${controller.vehiclesCount.value}',
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.green),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('FPS', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  Text(
                    controller.fps.value.replaceAll(' fps', ''),
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.blue),
                  ),
                ],
              ),
            ),
            if (controller.detections.isNotEmpty)
              SizedBox(
                width: 150,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('DETECCIONES', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    Wrap(
                      alignment: WrapAlignment.end,
                      children: controller.detections.take(2).map((det) {
                        return Container(
                          margin: const EdgeInsets.only(left: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.yellow.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            det['label'],
                            style: const TextStyle(fontSize: 10, color: Colors.yellow),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
          ],
        ),
      );
    });
  }
}