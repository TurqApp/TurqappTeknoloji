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
