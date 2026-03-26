part of 'my_tutoring_applications_controller.dart';

class MyTutoringApplicationsController extends GetxController {
  static const Duration _silentRefreshInterval = Duration(minutes: 5);
  final _state = _MyTutoringApplicationsControllerState();

  @override
  void onInit() {
    super.onInit();
    _handleInit();
  }
}
