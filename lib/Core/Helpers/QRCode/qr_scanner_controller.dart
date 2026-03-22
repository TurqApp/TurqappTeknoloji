import 'package:get/get.dart';

class QrScannerController extends GetxController {
  static QrScannerController ensure({
    String? tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      QrScannerController(),
      tag: tag,
      permanent: permanent,
    );
  }

  static QrScannerController? maybeFind({String? tag}) {
    final isRegistered = Get.isRegistered<QrScannerController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<QrScannerController>(tag: tag);
  }

  var scannedUserID = "".obs;

  void onDetect(String code) {
    scannedUserID.value = code;
    Get.back();
  }
}
