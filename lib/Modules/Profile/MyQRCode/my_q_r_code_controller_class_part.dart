part of 'my_q_r_code_controller.dart';

class MyQRCodeController extends GetxController {
  static MyQRCodeController ensure({String? tag, bool permanent = false}) =>
      maybeFind(tag: tag) ??
      Get.put(MyQRCodeController(), tag: tag, permanent: permanent);

  static MyQRCodeController? maybeFind({String? tag}) =>
      Get.isRegistered<MyQRCodeController>(tag: tag)
          ? Get.find<MyQRCodeController>(tag: tag)
          : null;

  final CurrentUserService userService = CurrentUserService.instance;
  final ShortLinkService _shortLinkService = ShortLinkService();
  final RxString profileLink = ''.obs;

  @override
  void onInit() {
    super.onInit();
    unawaited(_handleOnInit());
  }
}
