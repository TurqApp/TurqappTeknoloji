part of 'my_q_r_code_controller.dart';

extension _MyQrCodeControllerDataPart on MyQRCodeController {
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

  Future<void> _prepareProfileLink() async {
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
}
