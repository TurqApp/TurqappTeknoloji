part of 'saved_tests_controller.dart';

class SavedTestsController extends GetxController {
  static const Duration _silentRefreshInterval = Duration(minutes: 5);
  final _state = _SavedTestsControllerState();

  @override
  void onInit() {
    super.onInit();
    handleRuntimeInit();
  }
}
