part of 'job_finder_controller.dart';

class JobFinderController extends GetxController {
  final _state = _JobFinderControllerState();

  @override
  void onInit() {
    super.onInit();
    _handleOnInit();
  }

  @override
  void onClose() {
    _handleOnClose();
    super.onClose();
  }
}
