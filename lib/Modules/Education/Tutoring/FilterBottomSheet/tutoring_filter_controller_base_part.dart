part of 'tutoring_filter_controller.dart';

abstract class _TutoringFilterControllerBase extends GetxController {
  final _state = _TutoringFilterControllerState();

  @override
  void onInit() {
    super.onInit();
    _loadTutoringFilterCities(this as TutoringFilterController);
  }
}
