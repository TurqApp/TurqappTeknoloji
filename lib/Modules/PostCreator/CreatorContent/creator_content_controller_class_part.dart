part of 'creator_content_controller.dart';

class CreatorContentController extends _CreatorContentControllerBase {
  _CreatorContentControllerLifecyclePart get _lifecycle =>
      _CreatorContentControllerLifecyclePart(this);

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
