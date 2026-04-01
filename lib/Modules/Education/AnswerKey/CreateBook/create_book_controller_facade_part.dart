part of 'create_book_controller.dart';

extension CreateBookControllerFacadePart on CreateBookController {
  bool get isEditMode => existingBook != null;

  void handleBack() {
    if (selection.value != 0) {
      selection.value--;
    } else {
      Get.back();
    }
  }

  void nextStep() {
    selection.value++;
  }

  void selectSinavTuru(String value) {
    sinavTuru.value = value;
  }
}
