import 'package:get/get.dart';
import 'education_controller.dart';

class EducationBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<EducationController>(() => EducationController());
  }
}
