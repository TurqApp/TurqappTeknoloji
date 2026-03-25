part of 'short_snapshot_repository.dart';

class ShortSnapshotQuery {
  const ShortSnapshotQuery({
    required this.userId,
    this.limit = 20,
    this.scopeTag = 'home',
  });

  final String userId;
  final int limit;
  final String scopeTag;

  String get scopeId => <String>[
        'limit=$limit',
        'scope=${scopeTag.trim()}',
      ].join('|');
}
