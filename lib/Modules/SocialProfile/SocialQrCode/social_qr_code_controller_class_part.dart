part of 'social_qr_code_controller_library.dart';

class SocialQrCodeController extends GetxController {
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
