part of 'my_test_results_controller.dart';

class MyTestResultsController extends GetxController {
  static const Duration _silentRefreshInterval = Duration(minutes: 5);
  final _state = _MyTestResultsControllerState();

  @override
  void onInit() {
    super.onInit();
    handleRuntimeInit();
  }
}
