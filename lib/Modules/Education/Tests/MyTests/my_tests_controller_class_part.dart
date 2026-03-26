part of 'my_tests_controller.dart';

class MyTestsController extends GetxController {
  static const Duration _silentRefreshInterval = Duration(minutes: 5);
  final _state = _MyTestsControllerState();

  @override
  void onInit() {
    super.onInit();
    handleRuntimeInit();
  }
}
