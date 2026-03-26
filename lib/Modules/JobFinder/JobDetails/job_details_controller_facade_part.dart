part of 'job_details_controller.dart';

JobDetailsController ensureJobDetailsController({
  required JobModel model,
  String? tag,
  bool permanent = false,
}) =>
    maybeFindJobDetailsController(tag: tag) ??
    Get.put(
      JobDetailsController(model: model),
      tag: tag,
      permanent: permanent,
    );

JobDetailsController? maybeFindJobDetailsController({String? tag}) =>
    Get.isRegistered<JobDetailsController>(tag: tag)
        ? Get.find<JobDetailsController>(tag: tag)
        : null;

void _handleJobDetailsInit(JobDetailsController controller) {
  _JobDetailsControllerRuntimeX(controller).handleOnInit();
}

extension JobDetailsControllerFacadePart on JobDetailsController {
  String get _currentUserId => CurrentUserService.instance.effectiveUserId;
}
