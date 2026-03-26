part of 'search_tests_controller.dart';

class SearchTestsController extends GetxController {
  static const Duration _silentRefreshInterval = Duration(minutes: 5);
  final _state = _SearchTestsControllerState();

  @override
  void onInit() {
    super.onInit();
    _handleSearchTestsControllerInit(this);
  }

  @override
  void onClose() {
    _handleSearchTestsControllerClose(this);
    super.onClose();
  }
}
