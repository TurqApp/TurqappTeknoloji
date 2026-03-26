part of 'booklet_preview_controller.dart';

class BookletPreviewController extends GetxController {
  final _BookletPreviewControllerState _state;

  BookletPreviewController(BookletModel model)
      : _state = _BookletPreviewControllerState(model: model);

  @override
  void onInit() {
    super.onInit();
    _initialize();
  }
}
