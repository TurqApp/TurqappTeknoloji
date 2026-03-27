part of 'my_past_test_results_preview_controller.dart';

abstract class _MyPastTestResultsPreviewBase extends GetxController {
  _MyPastTestResultsPreviewBase(TestsModel model)
      : _state = _MyPastTestResultsPreviewControllerState(model);
  final _MyPastTestResultsPreviewControllerState _state;
}
