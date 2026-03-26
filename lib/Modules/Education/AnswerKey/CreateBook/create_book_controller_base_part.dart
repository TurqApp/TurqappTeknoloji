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
}
