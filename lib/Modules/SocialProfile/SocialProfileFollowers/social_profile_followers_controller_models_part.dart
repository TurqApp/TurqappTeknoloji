part of 'social_profile_followers_controller.dart';

class _RelationListCacheEntry {
  final List<String> ids;
  final DateTime cachedAt;

  const _RelationListCacheEntry({
    required this.ids,
    required this.cachedAt,
  });
}
