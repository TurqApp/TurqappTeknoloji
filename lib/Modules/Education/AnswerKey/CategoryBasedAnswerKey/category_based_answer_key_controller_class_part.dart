part of 'category_based_answer_key_controller.dart';

class CategoryBasedAnswerKeyController extends GetxController {
  static const Duration _silentRefreshInterval = Duration(minutes: 5);
  final _CategoryBasedAnswerKeyControllerState _state;

  CategoryBasedAnswerKeyController(String sinavTuru)
      : _state = _CategoryBasedAnswerKeyControllerState(sinavTuru: sinavTuru);

  @override
  void onInit() {
    super.onInit();
    _handleCategoryAnswerKeyInit();
  }

  @override
  void onClose() {
    _handleCategoryAnswerKeyClose();
    super.onClose();
  }
}
