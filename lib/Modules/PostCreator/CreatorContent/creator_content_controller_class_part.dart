part of 'creator_content_controller.dart';

class CreatorContentController extends GetxController
    with WidgetsBindingObserver {
  static CreatorContentController ensure({
    String? tag,
    bool permanent = false,
  }) =>
      _ensureCreatorContentController(tag: tag, permanent: permanent);

  static CreatorContentController? maybeFind({String? tag}) =>
      _maybeFindCreatorContentController(tag: tag);

  final _state = _CreatorContentControllerState();
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
