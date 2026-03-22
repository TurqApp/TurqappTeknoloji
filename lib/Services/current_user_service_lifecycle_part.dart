part of 'current_user_service.dart';

extension CurrentUserServiceLifecyclePart on CurrentUserService {
  Future<void> _performUpdateUser(CurrentUserModel user) async {
    final resolvedUser = await _applyStoredViewSelection(user);
    if (await _handlePermanentBanIfNeeded(resolvedUser)) {
      return;
    }
    _currentUser = resolvedUser;
    final didPublish = _publishResolvedUser(resolvedUser);
    await UserRepository.ensure().seedCurrentUser(resolvedUser);
    unawaited(_warmAvatar(resolvedUser));
    if (didPublish) {
      await _saveToCache(resolvedUser);
    }
  }

  Future<bool> _performHandlePermanentBanIfNeeded(
    CurrentUserModel user,
  ) async {
    if (!user.isPermanentAppBan || _handlingPermanentBan) {
      return false;
    }

    _handlingPermanentBan = true;
    try {
      AppSnackbar(
        'Hesap Engellendi',
        'Bu hesap uygulamaya erişimden kalıcı olarak uzaklaştırıldı.',
      );
      await _signOutToSignIn();
      return true;
    } catch (_) {
      return true;
    } finally {
      _handlingPermanentBan = false;
    }
  }

  Future<bool> _performHandleExclusiveSessionIfNeeded(
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
        await AccountCenterService.ensure()
            .registerCurrentDeviceSessionIfEnabled();
        return false;
      } catch (_) {}
    }
    if (DeviceSessionService.instance.hasPendingSessionClaim(uid)) {
      try {
        await AccountCenterService.ensure()
            .registerCurrentDeviceSessionIfEnabled();
        return false;
      } catch (_) {}
    }
    final legacyDeviceKey =
        (await DeviceSessionService.instance.getLegacyDeviceKey() ?? '').trim();
    if (legacyDeviceKey.isNotEmpty && activeDeviceKey == legacyDeviceKey) {
      try {
        await AccountCenterService.ensure()
            .registerCurrentDeviceSessionIfEnabled();
        return false;
      } catch (_) {}
    }

    _handlingSessionDisplacement = true;
    try {
      await AccountCenterService.ensure().markSessionState(
        uid: uid,
        isSessionValid: false,
        requiresReauth: true,
      );
      await AccountSessionVault.instance.delete(uid);
      AppSnackbar(
        'Oturum Kapatıldı',
        'Bu hesap başka bir telefonda açıldı. Yeniden giriş için şifre gerekir.',
      );
      await _signOutToSignIn(
        initialIdentifier: (data['email'] ?? '').toString().trim(),
      );
      return true;
    } catch (_) {
      return true;
    } finally {
      _handlingSessionDisplacement = false;
    }
  }

  bool _performPublishResolvedUser(CurrentUserModel user) {
    viewSelectionRx.value = user.viewSelection;
    final nextSignature = jsonEncode(user.toJson());
    if (_lastReactiveSignature == nextSignature) {
      return false;
    }
    _lastReactiveSignature = nextSignature;
    currentUserRx.value = user;
    _emitUserEvent(user);
    return true;
  }

  Future<void> _performWarmAvatar(CurrentUserModel? user) async {
    final url = (user?.avatarUrl ?? '').trim();
    if (url.isEmpty) return;
    if (_lastWarmedAvatarUrl == url) return;
    try {
      await TurqImageCacheManager.instance.getSingleFile(url);
      _lastWarmedAvatarUrl = url;
    } catch (_) {}
  }

  Future<void> _performSignOutToSignIn({
    String initialIdentifier = '',
  }) async {
    await logout();
    await signOutAuth();
    if (Get.key.currentContext == null) return;
    await Get.offAll(
      () => SignIn(
        initialIdentifier: initialIdentifier,
      ),
    );
  }

  Future<void> _performLogout() async {
    try {
      final oldUid = _currentUser?.userID;
      await _stopFirebaseSync();
      await _clearCache(oldUid);
      _purgeUserScopedCaches(oldUid);
      await FollowRepository.maybeFind()?.clearAll();
      _silentLogAt.clear();

      _cacheSaveTimer?.cancel();
      _cacheSaveTimer = null;
      _lastCacheSignature = null;
      _lastReactiveSignature = null;
      _lastRootSyncSignature = null;
      _lastWarmedAvatarUrl = null;

      _currentUser = null;
      viewSelectionRx.value = 1;
      currentUserRx.value = null;
      _emitUserEvent(null);

      _isInitialized = false;
      _isSyncing = false;
      emailVerifiedRx.value = true;
      _lastEmailPromptAt = null;
    } catch (_) {}
  }

  void _disposeLifecycleResources() {
    WidgetsBinding.instance.removeObserver(this);
    _stopFirebaseSync();
    _subdocCache.clear();
    _listCache.clear();
    _silentLogAt.clear();
    _userStreamController.close();
    CurrentUserService._instance = null;
  }

  void _handleLifecycleStateChange(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    final uid = authUserId;
    if (uid.isEmpty) return;
    unawaited(_validateExclusiveSessionFromServer(uid));
  }
}
