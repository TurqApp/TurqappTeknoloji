part of 'booklet_result_preview_controller.dart';

class _BookletResultPreviewControllerState {
  final Rx<BookletModel?> anaModel = Rx<BookletModel?>(null);
  final BookletRepository bookletRepository = BookletRepository.ensure();
}

extension BookletResultPreviewControllerFieldsPart
    on BookletResultPreviewController {
  Rx<BookletModel?> get anaModel => _state.anaModel;
  BookletRepository get _bookletRepository => _state.bookletRepository;
}
