part of 'profile_posts_snapshot_repository.dart';

class ProfilePostsSnapshotQuery {
  const ProfilePostsSnapshotQuery({
    required this.userId,
    this.limit = 24,
    this.scopeTag = 'my_profile',
  });

  final String userId;
  final int limit;
  final String scopeTag;

  String get scopeId => <String>[
        'limit=$limit',
        'scope=${scopeTag.trim()}',
      ].join('|');
}
