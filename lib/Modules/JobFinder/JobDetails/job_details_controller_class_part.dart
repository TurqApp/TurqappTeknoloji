part of 'job_details_controller.dart';

class JobDetailsController extends GetxController {
  static JobDetailsController ensure({
    required JobModel model,
    String? tag,
    bool permanent = false,
  }) =>
      _ensureJobDetailsController(
        model: model,
        tag: tag,
        permanent: permanent,
      );

  static JobDetailsController? maybeFind({String? tag}) =>
      _maybeFindJobDetailsController(tag: tag);

  final Rx<JobModel> model;
  final _state = _JobDetailsControllerState();

  JobDetailsController({required JobModel model}) : model = model.obs;

  @override
  void onInit() {
    super.onInit();
    _handleJobDetailsInit(this);
  }
}
