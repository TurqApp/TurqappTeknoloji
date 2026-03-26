part of 'story_repository.dart';

class StoryRepository extends GetxService {
  static const Duration _storyRowCacheTtl = Duration(minutes: 15);
  static const Duration _deletedStoriesCacheTtl = Duration(hours: 12);
  static const int _deletedStoriesCacheLimit = 100;

  UserProfileCacheService get _userCache =>
      _resolveStoryRepositoryUserCache(this);
  final _StoryRepositoryState _state = _StoryRepositoryState();

  static DateTime get _storyExpiryCutoff =>
      _storyRepositoryResolveStoryExpiryCutoff();

  static StoryRepository ensure() => _ensureStoryRepository();

  static StoryRepository? maybeFind() => _maybeFindStoryRepository();
}
