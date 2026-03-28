part of 'current_user_service.dart';

extension CurrentUserServiceSyncPart on CurrentUserService {
  CurrentUserSyncRole get _syncRole => CurrentUserSyncRole(this);

  Future<bool> _performInitialize() => _syncRole.initialize();

  Future<void> _performForceRefresh() => _syncRole.forceRefresh();

  Future<void> _performStartFirebaseSync() => _syncRole.startFirebaseSync();

  Future<void> _performAdoptFreshSessionKeyIfNeeded() =>
      CurrentUserAccountCenterRole(this).adoptFreshSessionKeyIfNeeded();

  void _performStartExclusiveSessionHeartbeat(String uid) =>
      _syncRole.startExclusiveSessionHeartbeat(uid);

  Future<void> _performValidateExclusiveSessionFromServer(String uid) =>
      _syncRole.validateExclusiveSessionFromServer(uid);

  Future<Map<String, dynamic>> _performBuildMergedUserData({
    required String uid,
    required Map<String, dynamic> rootData,
  }) =>
      _syncRole.buildMergedUserData(
        uid: uid,
        rootData: rootData,
      );

  Future<void> _performStopFirebaseSync() => _syncRole.stopFirebaseSync();
}
