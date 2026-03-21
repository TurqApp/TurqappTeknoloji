import 'package:get/get.dart';

class GlobalLoaderController extends GetxController {
  static GlobalLoaderController ensure({
    String? tag,
    bool permanent = true,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      GlobalLoaderController(),
      tag: tag,
      permanent: permanent,
    );
  }

  static GlobalLoaderController? maybeFind({String? tag}) {
    final isRegistered = Get.isRegistered<GlobalLoaderController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<GlobalLoaderController>(tag: tag);
  }

  var isOn = false.obs;
}
