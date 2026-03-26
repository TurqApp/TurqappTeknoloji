part of 'answer_key_controller.dart';

class AnswerKeyController extends GetxController {
  static AnswerKeyController ensure({bool permanent = false}) =>
      maybeFind() ?? Get.put(AnswerKeyController(), permanent: permanent);

  static AnswerKeyController? maybeFind() =>
      Get.isRegistered<AnswerKeyController>()
          ? Get.find<AnswerKeyController>()
          : null;

  static const String _listingSelectionPrefKeyPrefix =
      'pasaj_answer_key_listing_selection';
  static const int _pageSize = 30;
  final _AnswerKeyControllerState _state = _AnswerKeyControllerState();

  @override
  void onInit() {
    super.onInit();
    _handleControllerInit();
  }

  @override
  void onClose() {
    _handleControllerClose();
    super.onClose();
  }
}
