part of 'social_qr_code_controller.dart';

class SocialQrCodeController extends GetxController {
  static SocialQrCodeController ensure({
    required String userID,
    String? tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      SocialQrCodeController(userID: userID),
      tag: tag,
      permanent: permanent,
    );
  }

  static SocialQrCodeController? maybeFind({String? tag}) {
    final isRegistered = Get.isRegistered<SocialQrCodeController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<SocialQrCodeController>(tag: tag);
  }

  String userID;
  SocialQrCodeController({required this.userID});
  var nickname = "".obs;
  var profileImage = "".obs;
  final RxString profileLink = ''.obs;
  final ShortLinkService _shortLinkService = ShortLinkService();
  final UserSummaryResolver _userSummaryResolver = UserSummaryResolver.ensure();

  @override
  void onInit() {
    super.onInit();
    _handleSocialQrCodeOnInit();
  }
}
