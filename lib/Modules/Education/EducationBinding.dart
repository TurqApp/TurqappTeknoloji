import 'package:get/get.dart';
import 'EducationController.dart';

class EducationBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<EducationController>(() => EducationController());
  }
}
