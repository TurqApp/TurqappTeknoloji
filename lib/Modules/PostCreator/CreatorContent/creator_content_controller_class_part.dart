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

  @override
  void onInit() {
    super.onInit();
    _CreatorContentControllerLifecyclePart(this).handleOnInit();
  }

  @override
  void onClose() {
    _CreatorContentControllerLifecyclePart(this).handleOnClose();
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) =>
      _CreatorContentControllerLifecyclePart(this)
          .didChangeAppLifecycleState(state);
}
