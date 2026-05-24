// lib/pages/home/home_page.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:road_eye/pages/wellcome/wellcome_page.dart';
import 'home_controller.dart';
import '../wellcome/wellcome_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final HomeController control = Get.put(HomeController());

  int _currentIndex = 0;

  final List<Widget> _pages = [
    Center(child: WellcomePage()), // index 0
    Center(child: Text('Escanear QR')), // index 1
    Center(child: Text('Favoritos')), // index 2
  ];

  Widget _buildBody() {
    return _pages[_currentIndex];
  }

  void _onMenuSelected(String value) {
    switch (value) {
      case 'perfil':
        print('Ir a Ver Perfil');
        break;
      case 'acerca':
        print('Ir a Acerca de');
        break;
      case 'logout':
        print('Cerrar sesión');
        break;
    }
  }

  AppBar _appBar(ColorScheme colors) {
    return AppBar(
      title: Text('Road Eye'),
      backgroundColor: colors.primaryContainer,
      actions: [
        PopupMenuButton<String>(
          onSelected: _onMenuSelected,
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'acerca',
              child: Text('Acerca de'),
            ),
            PopupMenuItem(
              value: 'logout',
              child: Text('Cerrar Sesión'),
            ),
          ],
        ),
      ],
    );
  }

  BottomNavigationBar _bottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: (index) {
        setState(() {
          _currentIndex = index;
        });
      },
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
  Widget build(BuildContext context) {
    ColorScheme colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: _appBar(colors),
      body: _buildBody(),
      bottomNavigationBar: _bottomNavigationBar(),
    );
  }
}
