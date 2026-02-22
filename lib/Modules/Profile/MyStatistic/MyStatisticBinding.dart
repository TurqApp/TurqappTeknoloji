import 'package:get/get.dart';
import 'package:turqappv2/Modules/Profile/MyStatistic/MyStatisticController.dart';

class MyStatisticBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MyStatisticController>(() => MyStatisticController());
  }
}
