part of 'user_subdoc_repository.dart';

class _CachedUserSubdoc {
  final Map<String, dynamic> data;
  final DateTime cachedAt;

  const _CachedUserSubdoc({
    required this.data,
    required this.cachedAt,
  });
}
