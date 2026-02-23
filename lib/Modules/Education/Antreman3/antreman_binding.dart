import 'package:get/get.dart';
import 'package:turqappv2/Modules/Education/Antreman3/antreman_controller.dart';

class AntremanBindings extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AntremanController>(() => AntremanController());
  }
}
