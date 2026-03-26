part of 'deneme_sinavi_preview_controller.dart';

class DenemeSinaviPreviewController extends GetxController {
  final int fifteenMinutes = 15 * 60 * 1000;
  final _state = _DenemeSinaviPreviewControllerState();
  final SinavModel model;

  DenemeSinaviPreviewController({required this.model});

  @override
  void onInit() {
    super.onInit();
    _handleDenemeSinaviPreviewInit(this);
  }
}
