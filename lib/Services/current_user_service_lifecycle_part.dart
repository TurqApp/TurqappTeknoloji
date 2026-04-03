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

  bool _performPublishResolvedUser(CurrentUserModel user) {
    viewSelectionRx.value = user.viewSelection;
    final nextSignature = jsonEncode(user.toJson());
    if (_lastReactiveSignature == nextSignature) {
      return false;
    }
    _lastReactiveSignature = nextSignature;
    currentUserRx.value = user;
    if (!_userStreamController.isClosed) {
      _userStreamController.add(user);
    }
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
    await AppRootNavigationService.offAllToSignIn(
      initialIdentifier: initialIdentifier,
    );
  }

  Future<void> _performLogout() async {
    final previousUid = authUserId.trim();
    try {
      await _stopFirebaseSync();
      maybeFindUnreadMessagesController()?.stopListeners();
      await _clearActiveCachePointer();
      await maybeFindFollowRepository()?.clearAll();
      _silentLogAt.clear();
      if (previousUid.isNotEmpty) {
        _purgeUserScopedCaches(previousUid);
        await invalidateUserProfileCacheIfRegistered(previousUid);
        await ViewerSurfaceInvalidationService.invalidateForViewer(
          previousUid,
        );
      }

      _cacheSaveTimer?.cancel();
      _cacheSaveTimer = null;
      _lastCacheSignature = null;
      _lastReactiveSignature = null;
      _lastRootSyncSignature = null;
      _lastWarmedAvatarUrl = null;

      _currentUser = null;
      viewSelectionRx.value = 1;
      currentUserRx.value = null;
      if (!_userStreamController.isClosed) {
        _userStreamController.add(null);
      }

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
