part of 'answer_key_controller.dart';

class AnswerKeyController extends GetxController {
  static AnswerKeyController ensure({bool permanent = false}) {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(AnswerKeyController(), permanent: permanent);
  }

  static AnswerKeyController? maybeFind() {
    final isRegistered = Get.isRegistered<AnswerKeyController>();
    if (!isRegistered) return null;
    return Get.find<AnswerKeyController>();
  }

  static const String _listingSelectionPrefKeyPrefix =
      'pasaj_answer_key_listing_selection';
  final _AnswerKeyControllerState _state = _AnswerKeyControllerState();
  static const int _pageSize = 30;

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
