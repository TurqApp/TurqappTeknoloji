part of 'tutoring_controller.dart';

class TutoringController extends GetxController {
  final _state = _TutoringControllerState();

  static const int _pageSize = 30;
  bool get hasActiveSearch => _hasActiveTutoringSearch(this);

  @override
  void onInit() {
    super.onInit();
    _handleTutoringControllerInit(this);
  }

  @override
  void onClose() {
    _handleTutoringControllerClose(this);
    super.onClose();
  }
}
