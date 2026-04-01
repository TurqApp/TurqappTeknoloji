part of 'user_subcollection_repository.dart';

class UserSubcollectionEntry {
  final String id;
  final Map<String, dynamic> data;

  const UserSubcollectionEntry({
    required this.id,
    required this.data,
  });
}

class _CachedUserSubcollection {
  final List<UserSubcollectionEntry> items;
  final DateTime cachedAt;

  const _CachedUserSubcollection({
    required this.items,
    required this.cachedAt,
  });
}
