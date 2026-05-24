// lib/pages/home/home_page.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:road_eye/pages/plate_reader/plate_reader_controller.dart';
import 'package:road_eye/pages/plate_reader/plate_reader_page.dart';
import 'package:road_eye/pages/wellcome/wellcome_page.dart';
import 'home_controller.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final HomeController control = Get.put(HomeController());

  int _currentIndex = 0;
  
  // Controlador del lector de placas
  PlateReaderController? _plateController;
  
  // Indicador de si ya se inicializó el lector
  bool _plateReaderInitialized = false;

  final List<Widget> _pages = [
    Center(child: WellcomePage()), // index 0
    Center(child: PlateReaderPage()), // index 1
    const Center(child: Text('Favoritos')), // index 2
  ];

  Widget _buildBody() {
    return _pages[_currentIndex];
  }

  // Manejar cambio de pestaña
  void _onTabChanged(int index) async {
    // Si estamos saliendo de la pestaña del lector de placas (index 1)
    if (_currentIndex == 1 && index != 1) {
      // Cerrar recursos del lector de placas
      if (_plateController != null && Get.isRegistered<PlateReaderController>()) {
        await _plateController!.closeResources();
        
        // Eliminar el controlador de GetX para que se cree uno nuevo al volver
        if (Get.isRegistered<PlateReaderController>()) {
          await Get.delete<PlateReaderController>();
          _plateController = null;
          _plateReaderInitialized = false;
          
          if (kDebugMode) {
            print('✅ Controlador eliminado de GetX');
          }
        }
      }
    }
    
    // Cambiar al nuevo índice
    setState(() {
      _currentIndex = index;
    });
    
    // Si entramos a la pestaña del lector de placas, reinicializar
    if (index == 1 && !_plateReaderInitialized) {
      // Esperar un momento para que la página se construya
      Future.delayed(const Duration(milliseconds: 100), () {
        _initializePlateReader();
      });
    }
  }
  
  // Inicializar el lector de placas
  Future<void> _initializePlateReader() async {
    try {
      if (!Get.isRegistered<PlateReaderController>()) {
        _plateController = Get.put(PlateReaderController());
        _plateReaderInitialized = true;
        if (kDebugMode) {
          print('✅ Controlador del lector de placas inicializado');
        }
      } else {
        _plateController = Get.find<PlateReaderController>();
        _plateReaderInitialized = true;
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error inicializando lector de placas: $e');
      }
    }
  }

  void _onMenuSelected(String value) {
    switch (value) {
      case 'about':
        control.goToAbout(context);
        break;
      case 'exit':
        SystemNavigator.pop();
        break;
    }
  }

  AppBar _appBar(ColorScheme colors) {
    return AppBar(
      title: const Text('Road Eye'),
      backgroundColor: colors.primaryContainer,
      actions: [
        PopupMenuButton<String>(
          onSelected: _onMenuSelected,
          itemBuilder: (context) => const [
            PopupMenuItem(
              value: 'about',
              child: Text('Acerca de'),
            ),
            PopupMenuItem(
              value: 'exit',
              child: Text('Salir'),
            ),
          ],
        ),
      ],
    );
  }

  BottomNavigationBar _bottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: _onTabChanged, // Usar el nuevo método
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.co_present),
          label: 'Presentación',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.document_scanner),
          label: 'Escanear Placas',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.car_crash_sharp),
          label: 'Escanear Autos',
        ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    // No inicializar el lector automáticamente, solo cuando se necesite
  }

  @override
  void dispose() {
    // Cerrar recursos si el controlador existe al cerrar la app
    if (_plateController != null && Get.isRegistered<PlateReaderController>()) {
      _plateController!.closeResources();
      Get.delete<PlateReaderController>();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ColorScheme colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: _appBar(colors),
      body: _buildBody(),
      bottomNavigationBar: _bottomNavigationBar(),
    );
  }
}