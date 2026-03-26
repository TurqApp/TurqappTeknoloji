part of 'tutoring_search_controller.dart';

class TutoringSearchController extends GetxController {
  final _TutoringSearchControllerState _state =
      _TutoringSearchControllerState();

  @override
  void onInit() {
    super.onInit();
    unawaited(_handleOnInit());
  }

  @override
  void onClose() {
    _handleOnClose();
    super.onClose();
  }
}
