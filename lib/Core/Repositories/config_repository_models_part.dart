part of 'config_repository.dart';

class _CachedConfigDoc {
  final Map<String, dynamic> data;
  final DateTime cachedAt;

  const _CachedConfigDoc({
    required this.data,
    required this.cachedAt,
  });
}
