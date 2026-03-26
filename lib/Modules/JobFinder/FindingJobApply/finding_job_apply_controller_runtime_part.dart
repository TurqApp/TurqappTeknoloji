part of 'finding_job_apply_controller.dart';

void _handleFindingJobApplyControllerInit(
    FindingJobApplyController controller) {
  controller.cvCheck();
}

Future<void> _checkFindingJobCv(FindingJobApplyController controller) async {
  final uid = CurrentUserService.instance.effectiveUserId;
  if (uid.isEmpty) return;
  try {
    final data = await controller._cvRepository.getCv(uid, preferCache: true);
    controller.cvVar.value = data != null;
    if (data != null) {
      controller.isFinding.value = data['findingJob'] ?? false;
    }
  } catch (_) {}
}

Future<void> _toggleFindingJobState(
  FindingJobApplyController controller,
) async {
  final uid = CurrentUserService.instance.effectiveUserId;
  if (uid.isEmpty || !controller.cvVar.value) return;
  final next = !controller.isFinding.value;
  controller.isFinding.value = next;
  await controller._cvRepository.updateCvFields(uid, {'findingJob': next});
}

extension FindingJobApplyControllerRuntimeX on FindingJobApplyController {
  Future<void> cvCheck() => _checkFindingJobCv(this);

  Future<void> toggleFindingJob() => _toggleFindingJobState(this);
}
