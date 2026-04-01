part of 'job_content_controller.dart';

JobContentController ensureJobContentController({
  String? tag,
  bool permanent = false,
}) {
  final existing = maybeFindJobContentController(tag: tag);
  if (existing != null) return existing;
  return Get.put(
    JobContentController(),
    tag: tag,
    permanent: permanent,
  );
}

JobContentController? maybeFindJobContentController({String? tag}) {
  final isRegistered = Get.isRegistered<JobContentController>(tag: tag);
  if (!isRegistered) return null;
  return Get.find<JobContentController>(tag: tag);
}

Future<void> warmJobContentSavedIdsForCurrentUser() =>
    _warmSavedIdsForCurrentUserImpl();

extension JobContentControllerFacadePart on JobContentController {
  Future<void> primeSavedState(String docId) => _primeSavedStateImpl(docId);

  Future<void> toggleSave(String docId) => _toggleSaveImpl(docId);

  Future<void> reactivateEndedJob(JobModel model) =>
      _reactivateEndedJobImpl(model);

  Future<void> shareJob(JobModel model) => _shareJobImpl(model);
}
