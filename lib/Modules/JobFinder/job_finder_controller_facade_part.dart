part of 'job_finder_controller.dart';

JobFinderController ensureJobFinderController({bool permanent = false}) {
  final existing = maybeFindJobFinderController();
  if (existing != null) return existing;
  return Get.put(JobFinderController(), permanent: permanent);
}

JobFinderController? maybeFindJobFinderController() {
  final isRegistered = Get.isRegistered<JobFinderController>();
  if (!isRegistered) return null;
  return Get.find<JobFinderController>();
}
