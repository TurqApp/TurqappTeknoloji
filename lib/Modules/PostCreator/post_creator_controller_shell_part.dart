part of 'post_creator_controller.dart';

class PostCreatorController extends GetxController
    with WidgetsBindingObserver, _PostCreatorControllerBasePart {
  static PostCreatorController ensure({bool permanent = false}) =>
      _ensurePostCreatorController(permanent: permanent);

  static PostCreatorController? maybeFind() =>
      _maybeFindPostCreatorController();

  @override
  void onInit() {
    super.onInit();
    _handlePostCreatorControllerInit(this);
  }

  @override
  void onClose() {
    _handlePostCreatorControllerClose(this);
    super.onClose();
  }

  @override
  void didChangeMetrics() => _handlePostCreatorControllerMetrics(this);
}
