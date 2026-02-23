import 'package:get/get.dart';
import 'package:turqappv2/Modules/Profile/MyStatistic/my_statistic_controller.dart';

class MyStatisticBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MyStatisticController>(() => MyStatisticController());
  }
}
