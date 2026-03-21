import 'package:get/get.dart';

class GlobalLoaderController extends GetxController {
  static GlobalLoaderController _ensureService() {
    if (Get.isRegistered<GlobalLoaderController>()) {
      return Get.find<GlobalLoaderController>();
    }
    return Get.put(GlobalLoaderController(), permanent: true);
  }

  static GlobalLoaderController ensure() => _ensureService();

  var isOn = false.obs;
}
