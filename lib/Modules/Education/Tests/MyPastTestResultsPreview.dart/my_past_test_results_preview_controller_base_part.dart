part of 'my_past_test_results_preview_controller.dart';

abstract class _MyPastTestResultsPreviewControllerBase extends GetxController {
  _MyPastTestResultsPreviewControllerBase(TestsModel model)
      : _state = _MyPastTestResultsPreviewControllerState(model);
  final _MyPastTestResultsPreviewControllerState _state;
  @override
  void onInit() {
    super.onInit();
    (this as MyPastTestResultsPreviewController)._handleControllerInit();
  }
}
