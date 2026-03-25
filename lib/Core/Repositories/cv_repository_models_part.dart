part of 'cv_repository.dart';

class _CachedCv {
  final Map<String, dynamic>? data;
  final DateTime cachedAt;

  const _CachedCv({
    required this.data,
    required this.cachedAt,
  });
}
