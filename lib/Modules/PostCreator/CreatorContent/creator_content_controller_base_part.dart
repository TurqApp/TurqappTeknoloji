part of 'creator_content_controller.dart';

abstract class _CreatorContentControllerBase extends GetxController
    with WidgetsBindingObserver {
  final _state = _CreatorContentControllerState();

  _CreatorContentControllerLifecyclePart get _lifecycle =>
      _CreatorContentControllerLifecyclePart(this as CreatorContentController);

  @override
  void onInit() {
    super.onInit();
    _lifecycle.handleOnInit();
  }

  @override
  void onClose() {
    _lifecycle.handleOnClose();
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) =>
      _lifecycle.didChangeAppLifecycleState(state);
}
