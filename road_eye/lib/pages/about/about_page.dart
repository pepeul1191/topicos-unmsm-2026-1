// lib/pages/about/about_page.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:road_eye/components/auto_card.dart';


class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Equipo de Desarrollo'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Lista de autores
            Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Autor 1
                  const AuthorCard(
                    name: 'Edgar Oporto',
                    role: 'Lead Developer',
                    description: 'Especialista en Visión Computacional con más de 5 años de experiencia en desarrollo de sistemas de detección y reconocimiento de objetos.',
                    imageAsset: 'assets/images/author1.jpg',
                  ),
                  const SizedBox(height: 20),
                  // Autor 2
                  const AuthorCard(
                    name: 'José Valdivia',
                    role: 'Backend Developer',
                    description: 'Experta en Rails y Base de Datos. Apasionada por la arquitectura de software y el procesamiento eficiente de datos.',
                    imageAsset: 'assets/images/author2.jpg',
                  ),
                  const SizedBox(height: 20),
                  // Autor 3
                  const AuthorCard(
                    name: 'Juvitsa Plaza',
                    role: 'ML Engineer',
                    description: 'Especialista en YOLO y ETL. Enfocado en la implementación de modelos de machine learning en tiempo real.',
                    imageAsset: 'assets/images/author3.jpg',
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
            // Footer con tecnologías
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              margin: const EdgeInsets.only(top: 20),
              color: Colors.grey[100],
              child: Column(
                children: [
                  Text(
                    'Tecnologías utilizadas',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onTertiary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      _buildTechChip('Flutter', Colors.blue),
                      _buildTechChip('YOLO', Colors.green),
                      _buildTechChip('Rails', Colors.red),
                      _buildTechChip('SQLite', Colors.blueGrey),
                      _buildTechChip('LevelDB', Colors.orange),
                      _buildTechChip('GetX', Colors.purple),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    '© 2024 Road Eye - Todos los derechos reservados',
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

  Widget _buildTechChip(String label, Color color) {
    return Chip(
      label: Text(label),
      backgroundColor: color.withOpacity(0.1),
      labelStyle: TextStyle(color: color),
      side: BorderSide(color: color.withOpacity(0.3)),
    );
  }
}