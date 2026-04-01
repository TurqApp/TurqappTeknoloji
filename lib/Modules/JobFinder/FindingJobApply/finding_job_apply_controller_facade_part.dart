part of 'finding_job_apply_controller.dart';

FindingJobApplyController ensureFindingJobApplyController({
  String? tag,
  bool permanent = false,
}) {
  final existing = maybeFindFindingJobApplyController(tag: tag);
  if (existing != null) return existing;
  return Get.put(
    FindingJobApplyController(),
    tag: tag,
    permanent: permanent,
  );
}

FindingJobApplyController? maybeFindFindingJobApplyController({String? tag}) {
  final isRegistered = Get.isRegistered<FindingJobApplyController>(tag: tag);
  if (!isRegistered) return null;
  return Get.find<FindingJobApplyController>(tag: tag);
}
