part of 'deneme_sinavlari_controller.dart';

class DenemeSinavlariController extends GetxController {
  static DenemeSinavlariController ensure({
    bool permanent = false,
  }) =>
      _ensureDenemeSinavlariController(permanent: permanent);

  static DenemeSinavlariController? maybeFind() =>
      _maybeFindDenemeSinavlariController();
  final _state = _DenemeSinavlariControllerState();

  bool get hasActiveSearch => _hasActivePracticeExamSearch(this);

  @override
  void onInit() {
    super.onInit();
    _handleDenemeSinavlariInit(this);
  }

  @override
  void onClose() {
    _handleDenemeSinavlariClose(this);
    super.onClose();
  }
}
