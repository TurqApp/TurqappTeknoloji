part of 'job_creator_controller.dart';

class JobCreatorController extends GetxController {
  static JobCreatorController ensure({
    JobModel? existingJob,
    String? tag,
    bool permanent = false,
  }) =>
      maybeFind(tag: tag) ??
      Get.put(
        JobCreatorController(existingJob: existingJob),
        tag: tag,
        permanent: permanent,
      );

  static JobCreatorController? maybeFind({String? tag}) =>
      Get.isRegistered<JobCreatorController>(tag: tag)
          ? Get.find<JobCreatorController>(tag: tag)
          : null;

  final _shellState = _JobCreatorShellState();
  final JobModel? existingJob;

  JobCreatorController({this.existingJob});

  @override
  void onInit() {
    super.onInit();
    _handleOnInit();
  }

  @override
  void onClose() {
    _JobCreatorControllerSupportX(this).handleOnClose();
    super.onClose();
  }
}
