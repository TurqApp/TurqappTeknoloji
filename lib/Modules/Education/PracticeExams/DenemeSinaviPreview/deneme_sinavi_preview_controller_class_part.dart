part of 'deneme_sinavi_preview_controller_library.dart';

class DenemeSinaviPreviewController extends GetxController {
  final SinavModel model;

  DenemeSinaviPreviewController({required this.model});

  @override
  void onInit() {
    super.onInit();
    _handleDenemeSinaviPreviewInit(this);
  }
}
