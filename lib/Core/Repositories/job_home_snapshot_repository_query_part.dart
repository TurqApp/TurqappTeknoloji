part of 'job_home_snapshot_repository.dart';

class JobOwnerQuery {
  const JobOwnerQuery({
    required this.userId,
    required this.limit,
  });

  final String userId;
  final int limit;

  String buildScopeId({
    required int schemaVersion,
  }) {
    return CacheScopeNamespace.buildQueryScope(
      userId: userId,
      limit: limit,
      scopeTag: 'owner',
      schemaVersion: schemaVersion,
      qualifiers: <String, Object?>{
        'owner': userId.trim(),
        'limit': limit,
      },
    );
  }
}
