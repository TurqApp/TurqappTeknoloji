part of 'username_lookup_repository.dart';

class _UsernameCacheEntry {
  const _UsernameCacheEntry({
    required this.uid,
    required this.cachedAt,
  });

  final String? uid;
  final DateTime cachedAt;
}
