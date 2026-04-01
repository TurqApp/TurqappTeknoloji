part of 'follow_repository.dart';

class _CachedFollowingSet {
  final Set<String> ids;
  final DateTime cachedAt;

  const _CachedFollowingSet({
    required this.ids,
    required this.cachedAt,
  });
}
