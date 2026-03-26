part of 'category_based_answer_key_controller.dart';

abstract class _CategoryBasedAnswerKeyControllerBase extends GetxController {
  _CategoryBasedAnswerKeyControllerBase(String sinavTuru)
      : _state = _CategoryBasedAnswerKeyControllerState(sinavTuru: sinavTuru);

  final _CategoryBasedAnswerKeyControllerState _state;

  @override
  void onInit() {
    super.onInit();
    (this as CategoryBasedAnswerKeyController)._handleCategoryAnswerKeyInit();
  }

  @override
  void onClose() {
    (this as CategoryBasedAnswerKeyController)._handleCategoryAnswerKeyClose();
    super.onClose();
  }
}
