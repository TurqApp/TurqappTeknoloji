part of 'my_q_r_code_controller.dart';

extension MyQRCodeControllerRuntimeX on MyQRCodeController {
  String _buildProfileLink() {
    final nickname = normalizeProfileSlug(userService.nickname);
    if (nickname.isNotEmpty) {
      return buildTurqAppProfileUrl(nickname);
    }
    final uid = userService.effectiveUserId;
    if (uid.isNotEmpty) {
      return buildTurqAppProfileUrl(uid);
    }
    return buildTurqAppProfileUrl('guest');
  }

  String _fallbackProfileLink() {
    return _buildProfileLink();
  }

  Future<void> _handleOnInit() async {
    final link = _buildProfileLink();
    profileLink.value = link;
    final uid = userService.effectiveUserId;
    final nickname = normalizeProfileSlug(userService.nickname);
    if (uid.isEmpty || nickname.isEmpty) return;
    try {
      await _shortLinkService.upsertUser(
        userId: uid,
        slug: nickname,
        title: '@$nickname - TurqApp',
        desc: 'qr.profile_desc'.tr,
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
    final isAndroid13OrAbove = Platform.isAndroid;

    PermissionStatus status;

    if (isAndroid13OrAbove) {
      status = await Permission.photos.request();
    } else {
      status = await Permission.storage.request();
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
          dataModuleShape: QrDataModuleShape.square,
          color: Colors.black,
        ),
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
    } catch (_) {
      AppSnackbar('common.error'.tr, 'qr.download_failed'.tr);
    }
  }
}
