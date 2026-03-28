part of 'current_user_service.dart';

class CurrentUserAccountCenterRole {
  const CurrentUserAccountCenterRole(this.service);

  final CurrentUserService service;

  Future<void> adoptFreshSessionKeyIfNeeded() async {
    final uid = service.authUserId;
    if (uid.isEmpty) return;
    if (!DeviceSessionService.instance.consumeFreshKeyGenerationFlag()) return;
    try {
      await ensureAccountCenterService()
          .registerCurrentDeviceSessionIfEnabled();
    } catch (_) {}
  }

  Future<bool> handleExclusiveSessionIfNeeded(
    String uid,
    Map<String, dynamic> data,
  ) async {
    if (_handlingSessionDisplacement) return false;
    if (data['singleDeviceSessionEnabled'] != true) return false;
    final activeDeviceKey =
        (data['activeSessionDeviceKey'] ?? '').toString().trim();
    if (activeDeviceKey.isEmpty) return false;
    final localDeviceKey =
        await DeviceSessionService.instance.getOrCreateDeviceKey();
    if (activeDeviceKey == localDeviceKey) return false;
    if (DeviceSessionService.instance.consumeFreshKeyGenerationFlag()) {
      try {
        await ensureAccountCenterService()
            .registerCurrentDeviceSessionIfEnabled();
        return false;
      } catch (_) {}
    }
    if (DeviceSessionService.instance.hasPendingSessionClaim(uid)) {
      try {
        await ensureAccountCenterService()
            .registerCurrentDeviceSessionIfEnabled();
        return false;
      } catch (_) {}
    }
    final legacyDeviceKey =
        (await DeviceSessionService.instance.getLegacyDeviceKey() ?? '').trim();
    if (legacyDeviceKey.isNotEmpty && activeDeviceKey == legacyDeviceKey) {
      try {
        await ensureAccountCenterService()
            .registerCurrentDeviceSessionIfEnabled();
        return false;
      } catch (_) {}
    }

    _handlingSessionDisplacement = true;
    try {
      await ensureAccountCenterService().markSessionState(
        uid: uid,
        isSessionValid: false,
        requiresReauth: true,
      );
      await AccountSessionVault.instance.delete(uid);
      AppSnackbar(
        'Oturum Kapatıldı',
        'Bu hesap başka bir telefonda açıldı. Yeniden giriş için şifre gerekir.',
      );
      await service._signOutToSignIn(
        initialIdentifier: (data['email'] ?? '').toString().trim(),
      );
      return true;
    } catch (_) {
      return true;
    } finally {
      _handlingSessionDisplacement = false;
    }
  }
}
