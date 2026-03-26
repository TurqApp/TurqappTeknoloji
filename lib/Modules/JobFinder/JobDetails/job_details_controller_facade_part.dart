part of 'job_details_controller.dart';

class JobDetailsController extends GetxController {
  final Rx<JobModel> model;
  final _state = _JobDetailsControllerState();

  JobDetailsController({required JobModel model}) : model = model.obs;

  @override
  void onInit() {
    super.onInit();
    _handleJobDetailsInit(this);
  }
}

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
