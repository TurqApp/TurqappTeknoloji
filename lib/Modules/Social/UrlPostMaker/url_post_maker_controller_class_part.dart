part of 'url_post_maker_controller.dart';

class UrlPostMakerController extends GetxController {
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
