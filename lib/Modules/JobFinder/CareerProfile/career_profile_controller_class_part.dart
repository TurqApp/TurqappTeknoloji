part of 'career_profile_controller.dart';

class CareerProfileController extends GetxController {
  static const Duration _silentRefreshInterval = Duration(minutes: 5);
  final _state = _CareerProfileControllerState();

  @override
  void onInit() {
    super.onInit();
    _handleCareerProfileInit();
  }
}
