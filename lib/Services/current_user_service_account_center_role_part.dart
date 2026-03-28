part of 'current_user_service.dart';

class CurrentUserAccountCenterRole {
  CurrentUserAccountCenterRole(
    this.service, {
    StartupSessionFailureReporter? failureReporter,
  }) : _failureReporter =
           failureReporter ?? StartupSessionFailureReporter.defaultReporter;

  final CurrentUserService service;
  final StartupSessionFailureReporter _failureReporter;

  Future<void> adoptFreshSessionKeyIfNeeded() async {
    final uid = service.authUserId;
    if (uid.isEmpty) return;
    if (!DeviceSessionService.instance.consumeFreshKeyGenerationFlag()) return;
    try {
      await ensureAccountCenterService()
          .registerCurrentDeviceSessionIfEnabled();
    } catch (error, stackTrace) {
      _failureReporter.record(
        kind: StartupSessionFailureKind.accountCenterRegistration,
        operation: 'CurrentUserAccountCenterRole.adoptFreshSessionKeyIfNeeded',
        error: error,
        stackTrace: stackTrace,
      );
    }
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
      } catch (error, stackTrace) {
        _failureReporter.record(
          kind: StartupSessionFailureKind.accountCenterRegistration,
          operation:
              'CurrentUserAccountCenterRole.handleExclusiveSessionIfNeeded.freshKey',
          error: error,
          stackTrace: stackTrace,
        );
      }
    }
    if (DeviceSessionService.instance.hasPendingSessionClaim(uid)) {
      try {
        await ensureAccountCenterService()
            .registerCurrentDeviceSessionIfEnabled();
        return false;
      } catch (error, stackTrace) {
        _failureReporter.record(
          kind: StartupSessionFailureKind.accountCenterRegistration,
          operation:
              'CurrentUserAccountCenterRole.handleExclusiveSessionIfNeeded.pendingClaim',
          error: error,
          stackTrace: stackTrace,
        );
      }
    }
    final legacyDeviceKey =
        (await DeviceSessionService.instance.getLegacyDeviceKey() ?? '').trim();
    if (legacyDeviceKey.isNotEmpty && activeDeviceKey == legacyDeviceKey) {
      try {
        await ensureAccountCenterService()
            .registerCurrentDeviceSessionIfEnabled();
        return false;
      } catch (error, stackTrace) {
        _failureReporter.record(
          kind: StartupSessionFailureKind.accountCenterRegistration,
          operation:
              'CurrentUserAccountCenterRole.handleExclusiveSessionIfNeeded.legacyKey',
          error: error,
          stackTrace: stackTrace,
        );
      }
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
    } catch (error, stackTrace) {
      _failureReporter.record(
        kind: StartupSessionFailureKind.exclusiveSessionHandling,
        operation: 'CurrentUserAccountCenterRole.handleExclusiveSessionIfNeeded',
        error: error,
        stackTrace: stackTrace,
      );
      return true;
    } finally {
      _handlingSessionDisplacement = false;
    }
  }
}
