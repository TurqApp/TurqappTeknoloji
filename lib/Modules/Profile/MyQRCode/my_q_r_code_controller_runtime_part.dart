part of 'my_q_r_code_controller.dart';

MyQRCodeController ensureMyQRCodeController({
  String? tag,
  bool permanent = false,
}) =>
    maybeFindMyQRCodeController(tag: tag) ??
    Get.put(MyQRCodeController(), tag: tag, permanent: permanent);

MyQRCodeController? maybeFindMyQRCodeController({String? tag}) =>
    Get.isRegistered<MyQRCodeController>(tag: tag)
        ? Get.find<MyQRCodeController>(tag: tag)
        : null;

extension MyQRCodeControllerRuntimeX on MyQRCodeController {
  void _syncHeaderNickname(String nickname) {
    headerNickname.value = nickname.isNotEmpty ? '@$nickname' : '';
    debugPrint(
      '[MyQRCode] header_nickname '
      'rawService=${userService.nickname.trim()} '
      'rawCurrent=${userService.currentUserRx.value?.nickname.trim() ?? ''} '
      'rawAuthDisplay=${userService.authDisplayName.trim()} '
      'resolved=${headerNickname.value}',
    );
  }

  String _currentNicknameSlug() {
    final currentNickname =
        userService.currentUserRx.value?.nickname.trim() ?? '';
    final fallbackNickname = userService.nickname.trim();
    final raw = currentNickname.isNotEmpty ? currentNickname : fallbackNickname;
    return normalizeProfileSlug(raw);
  }

  Future<String> _resolveNicknameSlug() async {
    final local = _currentNicknameSlug();
    if (local.isNotEmpty) return local;
    final authDisplay = normalizeProfileSlug(userService.authDisplayName);
    if (authDisplay.isNotEmpty) return authDisplay;
    final uid = userService.effectiveUserId;
    if (uid.isEmpty) return '';
    var summary = await _userSummaryResolver.resolve(uid, preferCache: true);
    var nickname = normalizeProfileSlug(
      summary?.nickname.trim().isNotEmpty == true
          ? summary!.nickname
          : (summary?.username ?? ''),
    );
    if (nickname.isNotEmpty) return nickname;
    summary = await _userSummaryResolver.resolve(
      uid,
      preferCache: false,
      forceServer: true,
    );
    nickname = normalizeProfileSlug(
      summary?.nickname.trim().isNotEmpty == true
          ? summary!.nickname
          : (summary?.username ?? ''),
    );
    return nickname;
  }

  Future<String> _resolveProfileImageUrl() async {
    final local = userService.avatarUrl.trim();
    if (local.isNotEmpty) return local;
    final uid = userService.effectiveUserId;
    if (uid.isEmpty) return '';
    var summary = await _userSummaryResolver.resolve(uid, preferCache: true);
    var avatarUrl = (summary?.avatarUrl ?? '').trim();
    if (avatarUrl.isNotEmpty) return avatarUrl;
    summary = await _userSummaryResolver.resolve(
      uid,
      preferCache: false,
      forceServer: true,
    );
    avatarUrl = (summary?.avatarUrl ?? '').trim();
    return avatarUrl;
  }

  String _buildProfileLink({String? nicknameSlug}) {
    final nickname = nicknameSlug ?? normalizeProfileSlug(headerNickname.value);
    if (nickname.isNotEmpty) {
      return buildTurqAppProfileUrl(nickname);
    }
    final currentNickname = _currentNicknameSlug();
    if (currentNickname.isNotEmpty) {
      return buildTurqAppProfileUrl(currentNickname);
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
    final nickname = await _resolveNicknameSlug();
    _syncHeaderNickname(nickname);
    final link = _buildProfileLink(nicknameSlug: nickname);
    profileLink.value = link;
    final uid = userService.effectiveUserId;
    if (uid.isEmpty || nickname.isEmpty) return;
    final imageUrl = await _resolveProfileImageUrl();
    try {
      final result = await _shortLinkService.upsertUser(
        userId: uid,
        slug: nickname,
        title: '@$nickname - TurqApp',
        desc: 'qr.profile_desc'.tr,
        imageUrl: imageUrl,
      );
      final url = (result['url'] ?? '').toString().trim();
      if (url.isNotEmpty) {
        profileLink.value = url;
      }
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
      final nickname = await _resolveNicknameSlug();
      String link = _buildProfileLink(nicknameSlug: nickname);
      if (link.trim().isEmpty) {
        link = _fallbackProfileLink();
      }
      profileLink.value = link;
      await ShareLinkService.shareUrl(
        url: link,
        title: nickname.isNotEmpty ? '@$nickname - TurqApp' : 'TurqApp',
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
    if (!await AppImagePickerService.ensureGallerySavePermission()) {
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
