part of 'url_post_maker_controller.dart';

class UrlPostMakerController extends GetxController {
  static UrlPostMakerController ensure({
    String? tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      UrlPostMakerController(),
      tag: tag,
      permanent: permanent,
    );
  }

  static UrlPostMakerController? maybeFind({String? tag}) {
    final isRegistered = Get.isRegistered<UrlPostMakerController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<UrlPostMakerController>(tag: tag);
  }

  TextEditingController textEditingController = TextEditingController();
  Rx<HLSVideoAdapter?> videoPlayerController = Rx<HLSVideoAdapter?>(null);
  RxBool isPlaying = false.obs;
  RxBool yorum = true.obs;
  RxBool isSharing = false.obs;
  RxString adres = ''.obs;

  String? originalUserID;
  String? originalPostID;

  @override
  void onClose() {
    videoPlayerController.value?.dispose();
    textEditingController.dispose();
    super.onClose();
  }
}
