part of 'my_q_r_code_controller.dart';

MyQRCodeController ensureMyQRCodeController({
  String? tag,
  bool permanent = false,
}) =>
    maybeFindMyQRCodeController(tag: tag) ??
    Get.put(MyQRCodeController(), tag: tag, permanent: permanent);

MyQRCodeController? maybeFindMyQRCodeController({String? tag}) =>
    Get.isRegistered<MyQRCodeController>(tag: tag)
        ? Get.find<MyQRCodeController>(tag: tag)
        : null;
