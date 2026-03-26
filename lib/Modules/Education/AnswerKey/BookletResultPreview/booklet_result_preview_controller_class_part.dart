part of 'booklet_result_preview_controller.dart';

class BookletResultPreviewController extends GetxController {
  final BookletResultModel model;
  final _state = _BookletResultPreviewControllerState();

  BookletResultPreviewController(this.model) {
    _handleBookletResultPreviewInit(this);
  }
}
