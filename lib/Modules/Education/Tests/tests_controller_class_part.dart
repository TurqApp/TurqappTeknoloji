part of 'tests_controller.dart';

class TestsController extends GetxController {
  static const Duration _silentRefreshInterval = Duration(minutes: 5);
  static const int _pageSize = 30;
  final _state = _TestsControllerState();

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
