part of 'current_user_service.dart';

const bool _suppressCurrentUserSmokeLogs =
    bool.fromEnvironment('RUN_INTEGRATION_SMOKE', defaultValue: false);

extension CurrentUserServiceCachePart on CurrentUserService {
  CurrentUserCacheStore get _cacheStore => CurrentUserCacheStore(this);

  Future<void> _saveToCache(CurrentUserModel user) =>
      _cacheStore.saveToCache(user);

  Future<void> _clearActiveCachePointer() =>
      _cacheStore.clearActiveCachePointer();

  String _cacheKey(String uid) => _cacheStore.cacheKey(uid);

  void _purgeUserScopedCaches(String? uid) =>
      _cacheStore.purgeUserScopedCaches(uid);

  Future<Map<String, dynamic>> _readCachedRootUserDataSilently(
    String uid, {
    bool allowStaleMemory = true,
  }) =>
      _cacheStore.readCachedRootUserDataSilently(
        uid,
        allowStaleMemory: allowStaleMemory,
      );

  void _logSilently(String key, Object error, [StackTrace? stackTrace]) =>
      _cacheStore.logSilently(key, error, stackTrace);

  String _viewSelectionKey(String uid) => '${_viewSelectionPrefKeyPrefix}_$uid';

  int? _asNullableInt(Object? raw) {
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    if (raw == null || raw is FieldValue) return null;
    final value = raw.toString().trim();
    if (value.isEmpty) return null;
    return int.tryParse(value) ?? num.tryParse(value)?.toInt();
  }

  int? _extractRequestedViewSelection(Map<String, dynamic> fields) {
    return _asNullableInt(fields['viewSelection']);
  }

  Future<void> _persistViewSelection(String uid, int selection) async {
    if (uid.isEmpty) return;
    _prefs ??= await SharedPreferences.getInstance();
    _lastKnownViewSelection = selection;
    viewSelectionRx.value = selection;
    await _prefs?.setInt(_viewSelectionKey(uid), selection);
  }

  Future<CurrentUserModel> _applyStoredViewSelection(
    CurrentUserModel user,
  ) async {
    if (user.userID.isEmpty) return user;
    _prefs ??= await SharedPreferences.getInstance();
    final stored = _prefs?.getInt(_viewSelectionKey(user.userID));
    _lastKnownViewSelection = stored ?? user.viewSelection;
    if (stored == null || stored == user.viewSelection) {
      return user;
    }
    return user.copyWith(viewSelection: stored);
  }

  Future<void> _primeViewSelectionFromFirestore(String uid) async {
    if (uid.isEmpty) return;
    try {
      final hasLocalSelection = _lastKnownViewSelection != null;
      if (hasLocalSelection) {
        return;
      }
      final data = await _readCachedRootUserDataSilently(uid);
      if (data.isEmpty) return;
      final remote = _asNullableInt(data['viewSelection']);
      if (remote == null) return;

      await _persistViewSelection(uid, remote);
      final current = _currentUser;
      if (current != null &&
          current.userID == uid &&
          current.viewSelection != remote) {
        await _updateUser(current.copyWith(viewSelection: remote));
      }
    } catch (e, st) {
      _logSilently('prime.viewSelection', e, st);
    }
  }
}
