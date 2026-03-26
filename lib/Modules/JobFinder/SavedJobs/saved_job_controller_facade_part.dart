part of 'saved_job_controller_library.dart';

SavedJobsController ensureSavedJobsController({
  String? tag,
  bool permanent = false,
}) {
  final existing = maybeFindSavedJobsController(tag: tag);
  if (existing != null) return existing;
  return Get.put(
    SavedJobsController(),
    tag: tag,
    permanent: permanent,
  );
}

SavedJobsController? maybeFindSavedJobsController({String? tag}) {
  final isRegistered = Get.isRegistered<SavedJobsController>(tag: tag);
  if (!isRegistered) return null;
  return Get.find<SavedJobsController>(tag: tag);
}
