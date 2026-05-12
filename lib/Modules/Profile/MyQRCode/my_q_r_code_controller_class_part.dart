part of 'my_q_r_code_controller.dart';

class MyQRCodeController extends _MyQRCodeControllerBase {
  final userService = CurrentUserService.instance,
      _shortLinkService = ShortLinkService(),
      _userSummaryResolver = UserSummaryResolver.ensure(),
      headerNickname = ''.obs,
      profileLink = ''.obs;
}
