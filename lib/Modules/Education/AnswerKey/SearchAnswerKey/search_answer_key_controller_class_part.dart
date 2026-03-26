part of 'search_answer_key_controller.dart';

class SearchAnswerKeyController extends GetxController {
  final _state = _SearchAnswerKeyControllerState();

  @override
  void onInit() {
    super.onInit();
    _handleSearchAnswerKeyOnInit();
  }

  @override
  void onClose() {
    _handleSearchAnswerKeyOnClose();
    super.onClose();
  }
}
