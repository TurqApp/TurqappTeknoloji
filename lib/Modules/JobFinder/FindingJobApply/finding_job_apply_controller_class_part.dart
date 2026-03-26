part of 'finding_job_apply_controller.dart';

class FindingJobApplyController extends GetxController {
  final _FindingJobApplyControllerState _state =
      _FindingJobApplyControllerState();

  @override
  void onInit() {
    super.onInit();
    _handleFindingJobApplyControllerInit(this);
  }

  Future<void> cvCheck() => _checkFindingJobCv(this);

  Future<void> toggleFindingJob() => _toggleFindingJobState(this);
}
