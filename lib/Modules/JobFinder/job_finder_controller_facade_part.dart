part of 'job_finder_controller.dart';

JobFinderController ensureJobFinderController({bool permanent = false}) =>
    maybeFindJobFinderController() ??
    Get.put(JobFinderController(), permanent: permanent);

JobFinderController? maybeFindJobFinderController() =>
    Get.isRegistered<JobFinderController>()
        ? Get.find<JobFinderController>()
        : null;

extension JobFinderControllerFacadeApiPart on JobFinderController {
  Future<void> prepareStartupSurface({bool? allowBackgroundRefresh}) =>
      _performPrepareStartupSurface(
        allowBackgroundRefresh: allowBackgroundRefresh,
      );

  Future<void> persistStartupShard() => _persistJobFinderStartupShard();
}
