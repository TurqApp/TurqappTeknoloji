part of 'job_finder_controller.dart';

JobFinderController ensureJobFinderController({bool permanent = false}) =>
    maybeFindJobFinderController() ??
    Get.put(JobFinderController(), permanent: permanent);

JobFinderController? maybeFindJobFinderController() =>
    Get.isRegistered<JobFinderController>()
        ? Get.find<JobFinderController>()
        : null;
