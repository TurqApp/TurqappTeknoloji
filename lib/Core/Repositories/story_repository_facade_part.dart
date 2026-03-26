part of 'story_repository.dart';

StoryRepository _ensureStoryRepository() =>
    _maybeFindStoryRepository() ?? Get.put(StoryRepository(), permanent: true);

StoryRepository? _maybeFindStoryRepository() =>
    Get.isRegistered<StoryRepository>() ? Get.find<StoryRepository>() : null;

UserProfileCacheService _resolveStoryRepositoryUserCache(
  StoryRepository repository,
) =>
    repository._resolveUserCache();

int _storyRepositoryAsEpochMillis(
  StoryRepository repository,
  dynamic value, {
  int fallback = 0,
}) =>
    repository._performAsEpochMillis(value, fallback: fallback);

List<Map<String, dynamic>> _normalizeStoryRepositoryElements(
  StoryRepository repository,
  dynamic raw,
) =>
    repository._performNormalizeStoryElements(raw);

Future<void> _ensureStoryRepositoryInitialized(StoryRepository repository) =>
    repository._performEnsureInitialized();

String? _storyRepositoryCachePathForOwner(
  StoryRepository repository,
  String ownerUid,
) =>
    repository._performStoryRowCachePathForOwner(ownerUid);
