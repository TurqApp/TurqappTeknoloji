part of 'short_controller.dart';

abstract class _ShortControllerBase extends GetxController {
  final _state = _ShortControllerState();

  @override
  void onInit() {
    super.onInit();
    _ShortControllerRuntimeX(this as ShortController).handleOnInit();
  }

  @override
  void onClose() {
    _ShortControllerRuntimeX(this as ShortController).handleOnClose();
    super.onClose();
  }
}
