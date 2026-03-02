import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/Services/share_action_guard.dart';
import 'package:turqappv2/Core/Services/short_link_service.dart';
import '../../../Core/Helpers/QRCode/qr_scanner_view.dart';

class SocialQrCodeController extends GetxController {
  String userID;
  SocialQrCodeController({required this.userID});
  var nickname = "".obs;
  final RxString profileLink = ''.obs;
  final ShortLinkService _shortLinkService = ShortLinkService();
  @override
  void onInit() {
    // TODO: implement onInit
    super.onInit();
    FirebaseFirestore.instance
        .collection("users")
        .doc(userID)
        .get()
        .then((doc) {
      nickname.value = doc.get("nickname");
      unawaited(_prepareProfileLink());
    });
  }

  Future<String> _buildProfileLink() async {
    final slug = nickname.value.trim().toLowerCase();
    final safeSlug = slug.isEmpty ? userID : slug;
    final result = await _shortLinkService.upsertUser(
      userId: userID,
      slug: safeSlug,
      title: '@${nickname.value} - TurqApp',
      desc: 'TurqApp profilini görüntüle',
    );
    final url = (result['url'] ?? '').toString().trim();
    return url.isNotEmpty ? url : 'https://turqapp.com/u/$safeSlug';
  }

  Future<void> _prepareProfileLink() async {
    try {
      profileLink.value = await _buildProfileLink();
    } catch (_) {
      final slug = nickname.value.trim().toLowerCase();
      profileLink.value = 'https://turqapp.com/u/${slug.isEmpty ? userID : slug}';
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
      await SharePlus.instance.share(ShareParams(text: link));
    });
  }

  Future<void> copyLink() async {
    final link = await _buildProfileLink();
    profileLink.value = link;
    await Clipboard.setData(ClipboardData(text: link));
    AppSnackbar("Link Kopyalandı", "Profil linki panoya kopyalandı");
  }
}
