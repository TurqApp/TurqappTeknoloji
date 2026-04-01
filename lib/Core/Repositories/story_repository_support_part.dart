part of 'story_repository.dart';

extension StoryRepositorySupportPart on StoryRepository {
  Duration get storyRowCacheTtlInternal => StoryRepository._storyRowCacheTtl;

  Duration get deletedStoriesCacheTtlInternal =>
      StoryRepository._deletedStoriesCacheTtl;

  int get deletedStoriesCacheLimitInternal =>
      StoryRepository._deletedStoriesCacheLimit;

  DateTime get storyExpiryCutoffInternal => StoryRepository._storyExpiryCutoff;

  int _asEpochMillis(dynamic value, {int fallback = 0}) =>
      _storyRepositoryAsEpochMillis(this, value, fallback: fallback);

  List<Map<String, dynamic>> _normalizeStoryElements(dynamic raw) =>
      _normalizeStoryRepositoryElements(this, raw);

  Future<void> _ensureInitialized() => _ensureStoryRepositoryInitialized(this);

  String? _storyRowCachePathForOwner(String ownerUid) =>
      _storyRepositoryCachePathForOwner(this, ownerUid);
}
