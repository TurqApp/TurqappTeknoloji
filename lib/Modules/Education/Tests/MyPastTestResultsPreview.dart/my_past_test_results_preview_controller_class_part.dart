part of 'my_past_test_results_preview_controller.dart';

class MyPastTestResultsPreviewController extends GetxController {
  static const Duration _silentRefreshInterval = Duration(minutes: 5);
  MyPastTestResultsPreviewController(TestsModel model)
      : _state = _MyPastTestResultsPreviewControllerState(model);

  final _MyPastTestResultsPreviewControllerState _state;

  @override
  void onInit() {
    super.onInit();
    _handleControllerInit();
  }
}
