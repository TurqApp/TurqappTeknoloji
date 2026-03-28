part of 'job_finder_controller.dart';

JobFinderController ensureJobFinderController({bool permanent = false}) =>
    maybeFindJobFinderController() ??
    Get.put(JobFinderController(), permanent: permanent);

JobFinderController? maybeFindJobFinderController() =>
    Get.isRegistered<JobFinderController>()
        ? Get.find<JobFinderController>()
        : null;

Future<void> prepareJobFinderStartupSurface(
  JobFinderController controller, {
  bool? allowBackgroundRefresh,
}) =>
    controller._performPrepareStartupSurface(
      allowBackgroundRefresh: allowBackgroundRefresh,
    );

extension JobFinderControllerFacadeApiPart on JobFinderController {
  Future<void> persistStartupShard() => _persistJobFinderStartupShard();
}
