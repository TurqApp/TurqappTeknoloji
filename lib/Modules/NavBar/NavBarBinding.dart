import 'package:get/get.dart';
import 'NavBarController.dart';

class NavBarBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<NavBarController>(() => NavBarController());
  }
}
