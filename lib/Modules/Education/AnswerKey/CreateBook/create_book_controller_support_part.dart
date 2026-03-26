part of 'create_book_controller.dart';

extension CreateBookControllerSupportPart on CreateBookController {
  void _disposeCreateBookController() {
    baslikController.dispose();
    yayinEviController.dispose();
    basimTarihiController.dispose();
  }
}
