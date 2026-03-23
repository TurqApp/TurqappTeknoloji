part of 'finding_job_apply_controller.dart';

extension FindingJobApplyControllerActionsPart on FindingJobApplyController {
  Future<void> toggleFindingJob() async {
    final uid = CurrentUserService.instance.effectiveUserId;
    if (uid.isEmpty || !cvVar.value) return;
    final next = !isFinding.value;
    isFinding.value = next;
    await _cvRepository.updateCvFields(uid, {"findingJob": next});
  }
}
