part of 'user_repository.dart';

class _UserRepositoryState {
  final Map<String, _TimedUserLookup<bool>> existsCache =
      <String, _TimedUserLookup<bool>>{};
  final Map<String, _TimedUserLookup<Map<String, dynamic>?>> queryCache =
      <String, _TimedUserLookup<Map<String, dynamic>?>>{};
  final UserProfileCacheService cache = ensureUserProfileCacheService();
}

extension UserRepositoryFieldsPart on UserRepository {
  Map<String, _TimedUserLookup<bool>> get _existsCache => _state.existsCache;
  Map<String, _TimedUserLookup<Map<String, dynamic>?>> get _queryCache =>
      _state.queryCache;
  UserProfileCacheService get _cache => _state.cache;
}
