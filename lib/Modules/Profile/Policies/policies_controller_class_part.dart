part of 'policies_controller.dart';

class PoliciesController extends GetxController {
  static PoliciesController ensure({String? tag, bool permanent = false}) =>
      _ensurePoliciesController(tag: tag, permanent: permanent);

  static PoliciesController? maybeFind({String? tag}) =>
      _maybeFindPoliciesController(tag: tag);

  final _state = _PoliciesControllerState();

  @override
  void onInit() {
    super.onInit();
    _handlePoliciesInit(this);
  }

  @override
  void onClose() {
    _handlePoliciesClose(this);
    super.onClose();
  }
}
