part of 'deneme_sinavi_preview_controller.dart';

class DenemeSinaviPreviewController extends GetxController {
  static DenemeSinaviPreviewController ensure({
    required String tag,
    required SinavModel model,
    bool permanent = false,
  }) =>
      _ensureDenemeSinaviPreviewController(
        tag: tag,
        model: model,
        permanent: permanent,
      );

  static DenemeSinaviPreviewController? maybeFind({required String tag}) =>
      _maybeFindDenemeSinaviPreviewController(tag: tag);

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
