part of 'job_home_snapshot_repository.dart';

class JobOwnerQuery {
  const JobOwnerQuery({
    required this.userId,
  });

  final String userId;

  String buildScopeId({
    required int schemaVersion,
  }) {
    return CacheScopeNamespace.buildQueryScope(
      userId: userId,
      limit: 0,
      scopeTag: 'owner',
      schemaVersion: schemaVersion,
      qualifiers: <String, Object?>{
        'owner': userId.trim(),
      },
    );
  }
}
