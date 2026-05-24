// lib/pages/plate_reader/plate_reader_binding.dart
import 'package:get/get.dart';
import 'package:camera/camera.dart';
import 'package:road_eye/main.dart';
import 'plate_reader_controller.dart';

class PlateReaderBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PlateReaderController>(() {
      final cameraData = Get.find<CameraData>();
      final camera = cameraData.cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameraData.cameras.first,
      );
      return PlateReaderController();
    });
  }
}