part of 'my_applications_controller.dart';

class MyApplicationsController extends GetxController {
  @override
  void onInit() {
    super.onInit();
    unawaited(_bootstrapApplicationsImpl());
  }
}
