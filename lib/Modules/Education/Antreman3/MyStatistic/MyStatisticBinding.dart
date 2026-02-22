import 'package:get/get.dart';
import 'package:turqappv2/Modules/Education/Antreman3/MyStatistic/MyStatisticController.dart';

class MyStatisticBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MyStatisticController>(() => MyStatisticController());
  }
}
