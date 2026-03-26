part of 'tutoring_filter_controller_library.dart';

class TutoringFilterController extends _TutoringFilterControllerBase {}

TutoringFilterController? maybeFindTutoringFilterController() =>
    Get.isRegistered<TutoringFilterController>()
        ? Get.find<TutoringFilterController>()
        : null;

TutoringFilterController ensureTutoringFilterController({
  bool permanent = false,
}) =>
    maybeFindTutoringFilterController() ??
    Get.put(TutoringFilterController(), permanent: permanent);

abstract class _TutoringFilterControllerBase extends GetxController {
  final _state = _TutoringFilterControllerState();

  @override
  void onInit() {
    super.onInit();
    _loadTutoringFilterCities(this as TutoringFilterController);
  }
}
