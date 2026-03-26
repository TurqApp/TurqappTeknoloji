part of 'applications_controller_library.dart';

class ApplicationsController extends GetxController {
  @override
  void onInit() {
    super.onInit();
    unawaited(_handleOnInit());
  }
}
