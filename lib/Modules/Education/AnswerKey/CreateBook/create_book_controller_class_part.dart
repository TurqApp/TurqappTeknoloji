part of 'create_book_controller.dart';

class CreateBookController extends _CreateBookControllerBase {
  CreateBookController(
    Function? onBack, {
    BookletModel? existingBook,
  }) : super(
          onBack,
          existingBook: existingBook,
        );

  @override
  void onInit() {
    super.onInit();
    _handleControllerInit();
  }

  @override
  void onClose() {
    _disposeCreateBookController();
    super.onClose();
  }
}
