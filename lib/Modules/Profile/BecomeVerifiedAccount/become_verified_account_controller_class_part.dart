part of 'become_verified_account_controller.dart';

class BecomeVerifiedAccountController extends GetxController {
  static BecomeVerifiedAccountController ensure({
    String? tag,
    bool permanent = false,
  }) =>
      _ensureBecomeVerifiedAccountController(
        tag: tag,
        permanent: permanent,
      );

  static BecomeVerifiedAccountController? maybeFind({String? tag}) =>
      _maybeFindBecomeVerifiedAccountController(tag: tag);

  final _state = _BecomeVerifiedAccountControllerState();

  @override
  void onInit() {
    super.onInit();
    _handleBecomeVerifiedAccountInit(this);
  }

  @override
  void onClose() {
    _handleBecomeVerifiedAccountClose(this);
    super.onClose();
  }

  Future<bool> submitApplication() => _submitVerifiedAccountApplication(this);
}
