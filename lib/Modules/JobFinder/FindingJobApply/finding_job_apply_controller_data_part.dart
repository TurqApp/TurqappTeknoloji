part of 'finding_job_apply_controller.dart';

extension FindingJobApplyControllerDataPart on FindingJobApplyController {
  Future<void> cvCheck() async {
    final uid = CurrentUserService.instance.effectiveUserId;
    if (uid.isEmpty) return;
    try {
      final data = await _cvRepository.getCv(uid, preferCache: true);
      cvVar.value = data != null;
      if (data != null) {
        isFinding.value = data["findingJob"] ?? false;
      }
    } catch (_) {}
  }
}
