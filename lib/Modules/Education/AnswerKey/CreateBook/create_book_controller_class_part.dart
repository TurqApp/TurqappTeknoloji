part of 'create_book_controller.dart';

class CreateBookController extends GetxController {
  final _CreateBookControllerState _state;

  CreateBookController(
    Function? onBack, {
    BookletModel? existingBook,
  }) : _state = _CreateBookControllerState(
          onBack: onBack,
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
