import 'package:get/get.dart';
import 'package:turqappv2/Modules/Education/Tutoring/TutoringController.dart';

class TutoringBindings extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TutoringController>(() => TutoringController());
  }
}
