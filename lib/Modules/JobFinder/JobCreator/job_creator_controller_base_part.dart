part of 'job_creator_controller.dart';

abstract class _JobCreatorControllerBase extends GetxController {
  _JobCreatorControllerBase({this.existingJob});

  final _shellState = _JobCreatorShellState();
  final JobModel? existingJob;

  @override
  void onInit() {
    super.onInit();
    (this as JobCreatorController)._handleOnInit();
  }

  @override
  void onClose() {
    _JobCreatorControllerSupportX(this as JobCreatorController).handleOnClose();
    super.onClose();
  }
}
