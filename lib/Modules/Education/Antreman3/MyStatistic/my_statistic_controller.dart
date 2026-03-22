import 'package:get/get.dart';

class MyStatisticController extends GetxController {
  static MyStatisticController ensure({
    String? tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      MyStatisticController(),
      tag: tag,
      permanent: permanent,
    );
  }

  static MyStatisticController? maybeFind({String? tag}) {
    final isRegistered = Get.isRegistered<MyStatisticController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<MyStatisticController>(tag: tag);
  }

  var isloading = true.obs;
}
