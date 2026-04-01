part of 'url_post_maker_controller.dart';

abstract class _UrlPostMakerControllerBase extends GetxController {
  final TextEditingController textEditingController = TextEditingController();
  final Rx<HLSVideoAdapter?> videoPlayerController = Rx<HLSVideoAdapter?>(null);
  final RxBool isPlaying = false.obs;
  final RxBool yorum = true.obs;
  final RxBool isSharing = false.obs;
  final RxString adres = ''.obs;

  String? originalUserID;
  String? originalPostID;

  @override
  void onClose() {
    videoPlayerController.value?.dispose();
    textEditingController.dispose();
    super.onClose();
  }
}
