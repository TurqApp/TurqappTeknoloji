import 'cached_resource.dart';
import 'scoped_snapshot_store.dart';

enum CacheFirstEventType {
  memoryHit,
  scopedSnapshotHit,
  warmLaunchHit,
  liveSyncSkipped,
  liveSyncStarted,
  liveSyncSucceeded,
  liveSyncFailed,
  liveSyncPreservedPrevious,
}

class CacheFirstTelemetryEvent<T> {
  const CacheFirstTelemetryEvent({
    required this.type,
    required this.key,
    this.resource,
    this.error,
    this.stackTrace,
  });

  final CacheFirstEventType type;
  final ScopedSnapshotKey key;
  final CachedResource<T>? resource;
  final Object? error;
  final StackTrace? stackTrace;
}

abstract class CacheFirstTelemetry<T> {
  void onEvent(CacheFirstTelemetryEvent<T> event);
}

class NoopCacheFirstTelemetry<T> implements CacheFirstTelemetry<T> {
  const NoopCacheFirstTelemetry();

  @override
  void onEvent(CacheFirstTelemetryEvent<T> event) {}
}

