part of 'finding_job_apply_controller.dart';

class _FindingJobApplyControllerState {
  final CvRepository cvRepository = ensureCvRepository();
  final RxBool cvVar = false.obs;
  final RxBool isFinding = false.obs;
}

extension FindingJobApplyControllerFieldsPart on FindingJobApplyController {
  CvRepository get _cvRepository => _state.cvRepository;
  RxBool get cvVar => _state.cvVar;
  RxBool get isFinding => _state.isFinding;
}
