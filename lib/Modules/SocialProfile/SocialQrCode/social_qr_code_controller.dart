import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/Services/share_action_guard.dart';
import 'package:turqappv2/Core/Services/share_link_service.dart';
import 'package:turqappv2/Core/Services/short_link_service.dart';
import 'package:turqappv2/Core/Services/user_summary_resolver.dart';
import 'package:turqappv2/Core/Utils/nickname_utils.dart';
import 'package:turqappv2/Core/Utils/url_utils.dart';
import '../../../Core/Helpers/QRCode/qr_scanner_view.dart';

part 'social_qr_code_controller_runtime_part.dart';

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
