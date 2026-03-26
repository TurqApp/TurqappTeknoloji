part of 'create_book_controller.dart';

abstract class _CreateBookControllerBase extends GetxController {
  _CreateBookControllerBase(
    Function? onBack, {
    BookletModel? existingBook,
  }) : _state = _CreateBookControllerState(
          onBack: onBack,
          existingBook: existingBook,
        );

  final _CreateBookControllerState _state;

  @override
  void onInit() {
    super.onInit();
    (this as CreateBookController)._handleControllerInit();
  }

  @override
  void onClose() {
    (this as CreateBookController)._disposeCreateBookController();
    super.onClose();
  }
}
