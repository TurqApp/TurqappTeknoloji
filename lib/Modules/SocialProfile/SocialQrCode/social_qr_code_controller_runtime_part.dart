part of 'social_qr_code_controller_library.dart';

extension SocialQrCodeControllerRuntimePart on SocialQrCodeController {
  void _handleSocialQrCodeOnInit() {
    _loadUser();
  }

  Future<void> _loadUser() async {
    var data = await _userSummaryResolver.resolve(
      userID,
      preferCache: true,
    );
    if (data == null || _cleanQrNickname(data.nickname).isEmpty) {
      data = await _userSummaryResolver.resolve(
        userID,
        preferCache: false,
        forceServer: true,
      );
    }
    final current = CurrentUserService.instance;
    final isOwnProfile = current.effectiveUserId.trim() == userID.trim();
    final fallbackNickname =
        isOwnProfile ? _cleanQrNickname(current.nickname) : '';
    final resolvedNickname = _cleanQrNickname(data?.nickname ?? '').isNotEmpty
        ? _cleanQrNickname(data?.nickname ?? '')
        : fallbackNickname;
    final fallbackAvatar = isOwnProfile ? current.avatarUrl.trim() : '';
    final resolvedAvatar = (data?.avatarUrl ?? '').trim().isNotEmpty
        ? (data?.avatarUrl ?? '').trim()
        : fallbackAvatar;

    nickname.value = resolvedNickname.isNotEmpty ? '@$resolvedNickname' : '';
    profileImage.value = resolvedAvatar;
    unawaited(_prepareProfileLink());
  }

  Future<String> _buildProfileLink() async {
    final displayNickname = _displayQrNickname();
    final slug = normalizeProfileSlug(displayNickname);
    final safeSlug = slug.isEmpty ? userID : slug;
    final result = await _shortLinkService.upsertUser(
      userId: userID,
      slug: safeSlug,
      title: 'profile.profile_link_title'.trParams({
        'nickname': displayNickname,
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
      final slug = normalizeProfileSlug(_displayQrNickname());
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
          'nickname': _displayQrNickname(),
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

  String _cleanQrNickname(String raw) =>
      raw.trim().replaceFirst(RegExp(r'^@+'), '').trim();

  String _displayQrNickname() {
    final clean = _cleanQrNickname(nickname.value);
    if (clean.isNotEmpty) return '@$clean';
    final current = CurrentUserService.instance;
    final isOwnProfile = current.effectiveUserId.trim() == userID.trim();
    if (isOwnProfile) {
      final fallback = _cleanQrNickname(current.nickname);
      if (fallback.isNotEmpty) return '@$fallback';
    }
    return userID;
  }
}
