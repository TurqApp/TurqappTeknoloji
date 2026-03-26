part of 'tutoring_filter_controller_library.dart';

class TutoringFilterController extends _TutoringFilterControllerBase {}

abstract class _TutoringFilterControllerBase extends GetxController {
  final _state = _TutoringFilterControllerState();

  @override
  void onInit() {
    super.onInit();
    _loadTutoringFilterCities(this as TutoringFilterController);
  }
}
