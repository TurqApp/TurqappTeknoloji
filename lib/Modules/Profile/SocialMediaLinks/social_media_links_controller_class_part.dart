part of 'social_media_links_controller.dart';

class SocialMediaController extends GetxController {
  static const Duration _silentRefreshInterval = Duration(minutes: 5);
  final _state = _SocialMediaControllerState();

  @override
  void onInit() {
    super.onInit();
    _SocialMediaControllerRuntimeX(this).handleOnInit();
  }
}
