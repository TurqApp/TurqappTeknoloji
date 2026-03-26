part of 'create_book_controller.dart';

class CreateBookAnswerKeyController extends GetxController {
  static CreateBookAnswerKeyController ensure(
    CevapAnahtariHazirlikModel model,
    Function onBack, {
    String? tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      CreateBookAnswerKeyController(model, onBack),
      tag: tag,
      permanent: permanent,
    );
  }

  static CreateBookAnswerKeyController? maybeFind({String? tag}) {
    final isRegistered =
        Get.isRegistered<CreateBookAnswerKeyController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<CreateBookAnswerKeyController>(tag: tag);
  }

  final CevapAnahtariHazirlikModel model;
  final Function onBack;
  final baslikController = TextEditingController();
  final inputController = TextEditingController();
  final cevaplar = <String>[].obs;
  final onIzlendi = false.obs;

  CreateBookAnswerKeyController(this.model, this.onBack) {
    _initializeCreateBookAnswerKeyController(this);
  }

  @override
  void onClose() {
    baslikController.dispose();
    inputController.dispose();
    super.onClose();
  }

  void kaydetCevaplar() => _saveCreateBookAnswerKeyAnswers(this);

  void saveAndBack() => _saveCreateBookAnswerKeyAndBack(this);
}
