import 'cached_resource.dart';

class ScopedSnapshotKey {
  const ScopedSnapshotKey({
    required this.surfaceKey,
    required this.userId,
    this.scopeId = '',
  });

  final String surfaceKey;
  final String userId;
  final String scopeId;

  bool get isUserScoped => userId.trim().isNotEmpty;

  String get storageKey {
    final normalizedSurface = surfaceKey.trim();
    final normalizedUser = userId.trim();
    final normalizedScope = scopeId.trim();
    return <String>[
      normalizedSurface,
      normalizedUser,
      normalizedScope,
    ].join('::');
  }
}

class ScopedSnapshotRecord<T> {
  const ScopedSnapshotRecord({
    required this.data,
    required this.snapshotAt,
    required this.schemaVersion,
    required this.generationId,
    required this.source,
  });

  final T data;
  final DateTime snapshotAt;
  final int schemaVersion;
  final String generationId;
  final CachedResourceSource source;

  CachedResource<T> toCachedResource({
    bool isRefreshing = false,
    bool isStale = false,
    bool hasLiveError = false,
    Object? liveError,
    StackTrace? liveErrorStackTrace,
  }) {
    return CachedResource<T>(
      data: data,
      hasLocalSnapshot: true,
      isRefreshing: isRefreshing,
      isStale: isStale,
      hasLiveError: hasLiveError,
      snapshotAt: snapshotAt,
      source: source,
      liveError: liveError,
      liveErrorStackTrace: liveErrorStackTrace,
    );
  }
}

abstract class ScopedSnapshotStore<T> {
  Future<ScopedSnapshotRecord<T>?> read(
    ScopedSnapshotKey key, {
    bool allowStale = true,
  });

  Future<void> write(
    ScopedSnapshotKey key,
    ScopedSnapshotRecord<T> record,
  );

  Future<void> clearScope(ScopedSnapshotKey key);

  Future<void> clearSurface(
    String surfaceKey, {
    String? userId,
  });
}
