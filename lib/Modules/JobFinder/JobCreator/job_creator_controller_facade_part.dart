part of 'job_creator_controller.dart';

JobCreatorController ensureJobCreatorController({
  JobModel? existingJob,
  String? tag,
  bool permanent = false,
}) =>
    maybeFindJobCreatorController(tag: tag) ??
    Get.put(
      JobCreatorController(existingJob: existingJob),
      tag: tag,
      permanent: permanent,
    );

JobCreatorController? maybeFindJobCreatorController({String? tag}) =>
    Get.isRegistered<JobCreatorController>(tag: tag)
        ? Get.find<JobCreatorController>(tag: tag)
        : null;
