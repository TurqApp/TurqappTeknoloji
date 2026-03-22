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
    // TODO: implement onInit
    super.onInit();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final data = await _userSummaryResolver.resolve(
      userID,
      preferCache: true,
    );
    if (data == null) return;
    nickname.value = data.nickname;
    profileImage.value = data.avatarUrl;
    unawaited(_prepareProfileLink());
  }

  Future<String> _buildProfileLink() async {
    final slug = normalizeProfileSlug(nickname.value);
    final safeSlug = slug.isEmpty ? userID : slug;
    final result = await _shortLinkService.upsertUser(
      userId: userID,
      slug: safeSlug,
      title: 'profile.profile_link_title'.trParams({
        'nickname': nickname.value,
        'app': 'app.name'.tr,
      }),
      desc: 'qr.profile_desc'.tr,
      imageUrl: profileImage.value.trim().isNotEmpty
          ? profileImage.value.trim()
          : null,
    );
    final url = (result['url'] ?? '').toString().trim();
    return url.isNotEmpty ? url : buildTurqAppProfileUrl(safeSlug);
  }

  Future<void> _prepareProfileLink() async {
    try {
      profileLink.value = await _buildProfileLink();
    } catch (_) {
      final slug = normalizeProfileSlug(nickname.value);
      profileLink.value = buildTurqAppProfileUrl(
        slug.isEmpty ? userID : slug,
      );
    }
  }

  void showQrScannerModal() {
    Get.bottomSheet(
      QrScannerView(),
      isScrollControlled: true,
      backgroundColor: Colors.white,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    );
  }

  Future<void> shareProfile() async {
    await ShareActionGuard.run(() async {
      final link = await _buildProfileLink();
      profileLink.value = link;
      await ShareLinkService.shareUrl(
        url: link,
        title: 'profile.profile_link_title'.trParams({
          'nickname': nickname.value,
          'app': 'app.name'.tr,
        }),
        subject: 'profile.profile_share_title'.tr,
      );
    });
  }

  Future<void> copyLink() async {
    final link = await _buildProfileLink();
    profileLink.value = link;
    await Clipboard.setData(ClipboardData(text: link));
    AppSnackbar('qr.link_copied_title'.tr, 'qr.link_copied_body'.tr);
  }
}
