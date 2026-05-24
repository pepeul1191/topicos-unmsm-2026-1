// road_eye/lib/pages/wellcome/wellcome_page.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../components/auto_card.dart';
import '../../components/featured_card.dart';
import 'wellcome_controller.dart';

class WellcomePage extends StatelessWidget {
  WellcomePage({super.key});

  final WellcomeController controller = Get.put(WellcomeController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.primaryContainer,
                  ],
                ),
              ),
              child: Column(
                children: [
                  Image.asset(
                    'assets/img/icon-white.png',
                    width: 80,
                    height: 80,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Road Eye',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Sistema Inteligente de Monitoreo Vehicular',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            // Funcionalidades Section
            Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(
                    'Funcionalidades',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Tecnología de vanguardia para la seguridad vial',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),
                  // Tarjeta 1 - Escaneo de Placas
                  const FeatureCard(
                    icon: Icons.document_scanner,
                    title: 'Escaneo de Placas',
                    description: 'Lee y reconoce placas vehiculares en tiempo real utilizando YOLO. Consulta una base de datos en Rails + SQLite para obtener información del vehículo y su propietario.',
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 24),
                  // Tarjeta 2 - Monitoreo en Vivo
                  const FeatureCard(
                    icon: Icons.car_crash_sharp,
                    title: 'Monitoreo en Vivo',
                    description: 'Monitorea autos en circulación con detección YOLO. Sistema ETL con LevelDB para procesamiento y análisis de datos en tiempo real.',
                    color: Colors.green,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}