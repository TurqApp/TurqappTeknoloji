part of 'create_book_controller.dart';

final RegExp _createBookAnswerKeyOptionPattern = RegExp(r'[A-E]');

void _initializeCreateBookAnswerKeyController(
  CreateBookAnswerKeyController controller,
) {
  controller.baslikController.text = controller.model.baslik;
  controller.cevaplar.assignAll(controller.model.dogruCevaplar);
  controller.inputController.text = controller.model.dogruCevaplar.join();
}

void _saveCreateBookAnswerKeyAnswers(CreateBookAnswerKeyController controller) {
  controller.cevaplar.assignAll(
    controller.inputController.text
        .split('')
        .where(_createBookAnswerKeyOptionPattern.hasMatch)
        .toList(),
  );
  controller.onIzlendi.value = true;
}

void _saveCreateBookAnswerKeyAndBack(
  CreateBookAnswerKeyController controller,
) {
  controller.model.baslik = controller.baslikController.text;
  controller.model.dogruCevaplar = controller.cevaplar.toList();
  controller.onBack();
  Get.back();
}
