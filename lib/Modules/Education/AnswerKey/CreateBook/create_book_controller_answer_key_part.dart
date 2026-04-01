part of 'create_book_controller.dart';

final RegExp _createBookAnswerKeyOptionPattern = RegExp(r'[A-E]');

CreateBookAnswerKeyController ensureCreateBookAnswerKeyController(
  CevapAnahtariHazirlikModel model,
  Function onBack, {
  String? tag,
  bool permanent = false,
}) {
  final existing = maybeFindCreateBookAnswerKeyController(tag: tag);
  if (existing != null) return existing;
  return Get.put(
    CreateBookAnswerKeyController(model, onBack),
    tag: tag,
    permanent: permanent,
  );
}

CreateBookAnswerKeyController? maybeFindCreateBookAnswerKeyController({
  String? tag,
}) {
  final isRegistered =
      Get.isRegistered<CreateBookAnswerKeyController>(tag: tag);
  if (!isRegistered) return null;
  return Get.find<CreateBookAnswerKeyController>(tag: tag);
}

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

extension CreateBookAnswerKeyControllerFacadePart
    on CreateBookAnswerKeyController {
  void kaydetCevaplar() => _saveCreateBookAnswerKeyAnswers(this);

  void saveAndBack() => _saveCreateBookAnswerKeyAndBack(this);
}
