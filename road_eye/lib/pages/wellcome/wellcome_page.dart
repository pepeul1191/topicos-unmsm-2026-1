// road_eye/lib/pages/wellcome/wellcome_page.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
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
                    'assets/img/icon-white.png', // Ruta de tu imagen
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
                  _buildFeatureCard(
                    context,
                    icon: Icons.document_scanner,
                    title: 'Escaneo de Placas',
                    description:
                      'Lee y reconoce placas vehiculares en tiempo real utilizando YOLO. Consulta una base de datos en Rails + SQLite para obtener información del vehículo y su propietario.',
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 24),
                  // Tarjeta 2 - Monitoreo en Vivo
                  _buildFeatureCard(
                    context,
                    icon: Icons.car_crash_sharp,
                    title: 'Monitoreo en Vivo',
                    description:
                      'Monitorea autos en circulación con detección YOLO. Sistema ETL con LevelDB para procesamiento y análisis de datos en tiempo real.',
                    color: Colors.green,
                  ),
                ],
              ),
            ),
            // Autores Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              color: Colors.grey[100],
              child: Column(
                children: [
                  Text(
                    'Equipo de Desarrollo',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Conoce a los creadores de Road Eye',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 48),
                  // Autor 1
                  _buildAuthorCard(
                    context,
                    name: 'Juan Pérez',
                    role: 'Lead Developer',
                    description: 'Especialista en Visión Computacional',
                    imageAsset: 'assets/images/author1.jpg',
                  ),
                  const SizedBox(height: 24),
                  // Autor 2
                  _buildAuthorCard(
                    context,
                    name: 'María García',
                    role: 'Backend Developer',
                    description: 'Experta en Rails y Base de Datos',
                    imageAsset: 'assets/images/author2.jpg',
                  ),
                  const SizedBox(height: 24),
                  // Autor 3
                  _buildAuthorCard(
                    context,
                    name: 'Carlos López',
                    role: 'ML Engineer',
                    description: 'Especialista en YOLO y ETL',
                    imageAsset: 'assets/images/author3.jpg',
                  ),
                ],
              ),
            ),
            // Footer
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              color: Theme.of(context).colorScheme.primary,
              child: Column(
                children: [
                  Text(
                    '© 2024 Road Eye - Todos los derechos reservados',
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tecnología YOLO + Rails + LevelDB',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 48,
                color: color,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthorCard(
    BuildContext context, {
    required String name,
    required String role,
    required String description,
    required String imageAsset,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen - Columna izquierda
            CircleAvatar(
              radius: 40,
              backgroundImage: AssetImage(imageAsset),
              child: const Icon(Icons.person, size: 40), // Fallback
            ),
            const SizedBox(width: 16),
            // Datos de la persona - Columna derecha (expanded)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    role,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
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