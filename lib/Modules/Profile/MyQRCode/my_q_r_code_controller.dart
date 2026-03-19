import 'dart:async';
import 'dart:io';
import 'dart:ui' show ImageByteFormat;
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:saver_gallery/saver_gallery.dart';
import 'package:turqappv2/Core/Services/share_link_service.dart';
import 'package:turqappv2/Core/Services/short_link_service.dart';
import 'package:turqappv2/Core/Services/share_action_guard.dart';
import 'package:turqappv2/Services/current_user_service.dart';

import '../../../Core/Helpers/QRCode/qr_scanner_view.dart';

class MyQRCodeController extends GetxController {
  final CurrentUserService userService = CurrentUserService.instance;
  final ShortLinkService _shortLinkService = ShortLinkService();
  final RxString profileLink = ''.obs;

  @override
  void onInit() {
    super.onInit();
    unawaited(_prepareProfileLink());
  }

  String _buildProfileLink() {
    final nickname = userService.nickname.trim();
    if (nickname.isNotEmpty) {
      return 'https://turqapp.com/u/$nickname';
    }
    final uid = userService.userId.isNotEmpty
        ? userService.userId
        : (FirebaseAuth.instance.currentUser?.uid ?? '');
    if (uid.isNotEmpty) {
      return 'https://turqapp.com/u/$uid';
    }
    return 'https://turqapp.com/u/guest';
  }

  String _fallbackProfileLink() {
    return _buildProfileLink();
  }

  Future<void> _prepareProfileLink() async {
    final link = _buildProfileLink();
    profileLink.value = link;
    final uid = userService.userId.isNotEmpty
        ? userService.userId
        : (FirebaseAuth.instance.currentUser?.uid ?? '');
    final nickname = userService.nickname.trim();
    if (uid.isEmpty || nickname.isEmpty) return;
    try {
      await _shortLinkService.upsertUser(
        userId: uid,
        slug: nickname,
        title: '@$nickname - TurqApp',
        desc: 'TurqApp profilini görüntüle',
        imageUrl: userService.avatarUrl,
      );
    } catch (_) {}
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
      String link = _buildProfileLink();
      if (link.trim().isEmpty) {
        link = _fallbackProfileLink();
      }
      profileLink.value = link;
      await ShareLinkService.shareUrl(
        url: link,
        title: '@${userService.nickname} - TurqApp',
        subject: 'qr.profile_subject'.tr,
      );
    });
  }

  Future<void> copyLink() async {
    final link = _buildProfileLink();
    profileLink.value = link;
    await Clipboard.setData(ClipboardData(text: link));
    AppSnackbar('qr.link_copied_title'.tr, 'qr.link_copied_body'.tr);
  }

  Future<void> downloadQRCode() async {
    // Android 13 ve sonrası için özel medya izni
    final isAndroid13OrAbove = Platform.isAndroid;

    PermissionStatus status;

    if (isAndroid13OrAbove) {
      status = await Permission.photos
          .request(); // PNG formatı için fotoğraflar izni
    } else {
      status =
          await Permission.storage.request(); // Eski Android sürümleri için
    }

    if (!status.isGranted) {
      AppSnackbar(
        'qr.permission_required'.tr,
        'qr.gallery_permission_body'.tr,
      );
      return;
    }

    try {
      final qrPainter = QrPainter(
        data: profileLink.value.isNotEmpty
            ? profileLink.value
            : _buildProfileLink(),
        version: QrVersions.auto,
        gapless: true,
        eyeStyle:
            const QrEyeStyle(eyeShape: QrEyeShape.square, color: Colors.black),
        dataModuleStyle: const QrDataModuleStyle(
            dataModuleShape: QrDataModuleShape.square, color: Colors.black),
      );

      final picData = await qrPainter.toImageData(
        1000,
        format: ImageByteFormat.png,
      );
      if (picData == null) {
        AppSnackbar('common.error'.tr, 'qr.data_failed'.tr);
        return;
      }

      final Uint8List pngBytes = picData.buffer.asUint8List();
      final fileName = 'qr_${DateTime.now().millisecondsSinceEpoch}.png';

      final result = await SaverGallery.saveImage(
        pngBytes,
        fileName: fileName,
        skipIfExists: false,
      );

      if (result.isSuccess) {
        AppSnackbar('common.success'.tr, 'qr.saved'.tr);
      } else {
        AppSnackbar('common.error'.tr, 'qr.save_failed'.tr);
      }
    } catch (e) {
      AppSnackbar('common.error'.tr, 'qr.download_failed'.tr);
    }
  }
}
