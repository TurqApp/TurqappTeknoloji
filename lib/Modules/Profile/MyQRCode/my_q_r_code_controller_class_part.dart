part of 'my_q_r_code_controller.dart';

class MyQRCodeController extends GetxController {
  static MyQRCodeController ensure({
    String? tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      MyQRCodeController(),
      tag: tag,
      permanent: permanent,
    );
  }

  static MyQRCodeController? maybeFind({String? tag}) {
    final isRegistered = Get.isRegistered<MyQRCodeController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<MyQRCodeController>(tag: tag);
  }

  final CurrentUserService userService = CurrentUserService.instance;
  final ShortLinkService _shortLinkService = ShortLinkService();
  final RxString profileLink = ''.obs;

  @override
  void onInit() {
    super.onInit();
    unawaited(_handleOnInit());
  }
}
