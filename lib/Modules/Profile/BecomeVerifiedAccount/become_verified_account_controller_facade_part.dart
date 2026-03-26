part of 'become_verified_account_controller.dart';

BecomeVerifiedAccountController _ensureBecomeVerifiedAccountController({
  String? tag,
  bool permanent = false,
}) =>
    _maybeFindBecomeVerifiedAccountController(tag: tag) ??
    Get.put(
      BecomeVerifiedAccountController(),
      tag: tag,
      permanent: permanent,
    );

BecomeVerifiedAccountController? _maybeFindBecomeVerifiedAccountController({
  String? tag,
}) =>
    Get.isRegistered<BecomeVerifiedAccountController>(tag: tag)
        ? Get.find<BecomeVerifiedAccountController>(tag: tag)
        : null;

void _handleBecomeVerifiedAccountInit(
  BecomeVerifiedAccountController controller,
) {
  _BecomeVerifiedAccountControllerRuntimeX(controller).handleOnInit();
}

void _handleBecomeVerifiedAccountClose(
  BecomeVerifiedAccountController controller,
) {
  _BecomeVerifiedAccountControllerRuntimeX(controller).handleOnClose();
}

Future<bool> _submitVerifiedAccountApplication(
  BecomeVerifiedAccountController controller,
) =>
    _BecomeVerifiedAccountControllerRuntimeX(controller).submitApplication();
