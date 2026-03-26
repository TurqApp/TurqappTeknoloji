part of 'job_creator_controller.dart';

class JobCreatorController extends GetxController {
  final _shellState = _JobCreatorShellState();
  final JobModel? existingJob;

  JobCreatorController({this.existingJob});

  @override
  void onInit() {
    super.onInit();
    _handleOnInit();
  }

  @override
  void onClose() {
    _JobCreatorControllerSupportX(this).handleOnClose();
    super.onClose();
  }
}
