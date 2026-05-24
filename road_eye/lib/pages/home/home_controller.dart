import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

class HomeController extends GetxController {
  void goToAbout(BuildContext context){
    Navigator.pushNamed(context, '/about');
  }
}
