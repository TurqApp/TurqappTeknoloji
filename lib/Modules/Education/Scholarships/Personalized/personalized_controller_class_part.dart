part of 'personalized_controller.dart';

class PersonalizedController extends GetxController
    with _PersonalizedControllerBasePart {
  static PersonalizedController ensure({
    required String tag,
    bool permanent = false,
  }) =>
      _ensurePersonalizedController(tag: tag, permanent: permanent);

  static PersonalizedController? maybeFind({String? tag}) =>
      _maybeFindPersonalizedController(tag: tag);

  @override
  void onInit() {
    super.onInit();
    _handlePersonalizedControllerInit(this);
  }

  @override
  void onClose() {
    _handlePersonalizedControllerClose(this);
    super.onClose();
  }
}
