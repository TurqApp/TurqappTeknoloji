part of 'booklet_result_preview_controller.dart';

class BookletResultPreviewController extends GetxController {
  final BookletResultModel model;
  final _state = _BookletResultPreviewControllerState();

  BookletResultPreviewController(this.model) {
    _handleBookletResultPreviewInit(this);
  }
}

class _BookletResultPreviewControllerState {
  final Rx<BookletModel?> anaModel = Rx<BookletModel?>(null);
  final BookletRepository bookletRepository = ensureBookletRepository();
}

extension BookletResultPreviewControllerFieldsPart
    on BookletResultPreviewController {
  Rx<BookletModel?> get anaModel => _state.anaModel;
  BookletRepository get _bookletRepository => _state.bookletRepository;
}
