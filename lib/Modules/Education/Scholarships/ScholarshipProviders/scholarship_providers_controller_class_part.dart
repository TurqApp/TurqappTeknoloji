part of 'scholarship_providers_controller.dart';

class ScholarshipProvidersController extends GetxController {
  final _ScholarshipProvidersControllerState _state =
      _ScholarshipProvidersControllerState();
  static const Duration _silentRefreshInterval = Duration(minutes: 5);

  @override
  void onInit() {
    super.onInit();
    _handleInit();
  }
}
