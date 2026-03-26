part of 'social_qr_code_controller.dart';

SocialQrCodeController ensureSocialQrCodeController({
  required String userID,
  String? tag,
  bool permanent = false,
}) {
  final existing = maybeFindSocialQrCodeController(tag: tag);
  if (existing != null) return existing;
  return Get.put(
    SocialQrCodeController(userID: userID),
    tag: tag,
    permanent: permanent,
  );
}

SocialQrCodeController? maybeFindSocialQrCodeController({String? tag}) {
  final isRegistered = Get.isRegistered<SocialQrCodeController>(tag: tag);
  if (!isRegistered) return null;
  return Get.find<SocialQrCodeController>(tag: tag);
}
