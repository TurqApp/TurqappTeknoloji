import 'package:get/get.dart';

class GlobalLoaderController extends GetxController {
  static GlobalLoaderController _ensureService() {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(GlobalLoaderController(), permanent: true);
  }

  static GlobalLoaderController ensure() => _ensureService();

  static GlobalLoaderController? maybeFind() {
    if (!Get.isRegistered<GlobalLoaderController>()) return null;
    return Get.find<GlobalLoaderController>();
  }

  var isOn = false.obs;
}
