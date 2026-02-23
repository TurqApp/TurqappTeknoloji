import 'package:get/get.dart';
import 'package:turqappv2/Modules/Education/Tutoring/tutoring_controller.dart';

class TutoringBindings extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TutoringController>(() => TutoringController());
  }
}
