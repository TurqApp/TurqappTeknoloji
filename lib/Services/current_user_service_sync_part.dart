part of 'current_user_service.dart';

extension CurrentUserServiceSyncPart on CurrentUserService {
  CurrentUserSyncRole get _syncRole => CurrentUserSyncRole(this);

  Future<bool> _performInitialize() => _syncRole.initialize();

  Future<void> _performForceRefresh() => _syncRole.forceRefresh();

  Future<void> _performValidateExclusiveSessionFromServer(String uid) =>
      _syncRole.validateExclusiveSessionFromServer(uid);

  Future<void> _performStopFirebaseSync() => _syncRole.stopFirebaseSync();
}
