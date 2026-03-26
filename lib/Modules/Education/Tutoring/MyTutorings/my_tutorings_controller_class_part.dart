part of 'my_tutorings_controller.dart';

class MyTutoringsController extends GetxController {
  static const Duration _silentRefreshInterval = Duration(minutes: 5);
  final _state = _MyTutoringsControllerState();

  @override
  void onInit() {
    super.onInit();
    _handleMyTutoringsInit();
  }

  @override
  void onClose() {
    _handleMyTutoringsClose();
    super.onClose();
  }
}
