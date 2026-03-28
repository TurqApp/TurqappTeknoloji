import 'dart:async';

import 'cache_first_policy.dart';
import 'cache_first_telemetry.dart';
import 'cached_resource.dart';
import 'scoped_snapshot_store.dart';

typedef CacheFirstLiveFetcher<T> = Future<T> Function();
typedef CacheFirstWarmSnapshotReader<T> = Future<T?> Function();
typedef CacheFirstIsEmpty<T> = bool Function(T value);

class CacheFirstCoordinator<T> {
  CacheFirstCoordinator({
    required this.memoryStore,
    required this.snapshotStore,
    this.policy = const CacheFirstPolicy(),
    CacheFirstTelemetry<T>? telemetry,
  }) : _telemetry = telemetry ?? NoopCacheFirstTelemetry<T>();

  final ScopedSnapshotStore<T> memoryStore;
  final ScopedSnapshotStore<T> snapshotStore;
  final CacheFirstPolicy policy;
  final CacheFirstTelemetry<T> _telemetry;

  final Map<String, DateTime> _lastLiveSyncAtByKey = <String, DateTime>{};

  Stream<CachedResource<T>> open(
    ScopedSnapshotKey key, {
    required CacheFirstLiveFetcher<T> fetchLive,
    CacheFirstWarmSnapshotReader<T>? loadWarmSnapshot,
    CacheFirstIsEmpty<T>? isEmpty,
    bool forceSync = false,
    CachedResourceSource liveSource = CachedResourceSource.server,
    int schemaVersion = 1,
    String? generationId,
  }) async* {
    final initial = await bootstrap(
      key,
      loadWarmSnapshot: loadWarmSnapshot,
      schemaVersion: schemaVersion,
    );
    final shouldSync = _shouldSync(
      key: key,
      current: initial,
      forceSync: forceSync,
    );

    if (!shouldSync) {
      _telemetry.onEvent(
        CacheFirstTelemetryEvent<T>(
          type: CacheFirstEventType.liveSyncSkipped,
          key: key,
          resource: initial,
        ),
      );
      yield initial;
      return;
    }

    final refreshing = initial.copyWith(
      isRefreshing: true,
      hasLiveError: false,
      liveError: null,
      liveErrorStackTrace: null,
    );
    yield refreshing;
    yield await sync(
      key,
      current: refreshing,
      fetchLive: fetchLive,
      isEmpty: isEmpty,
      liveSource: liveSource,
      schemaVersion: schemaVersion,
      generationId: generationId,
    );
  }

  Future<CachedResource<T>> bootstrap(
    ScopedSnapshotKey key, {
    CacheFirstWarmSnapshotReader<T>? loadWarmSnapshot,
    int schemaVersion = 1,
  }) async {
    final memory = await memoryStore.read(key, allowStale: true);
    if (memory != null && _isCompatibleSchema(memory, schemaVersion)) {
      final resource = memory
          .toCachedResource(
            isStale: policy.isSnapshotStale(memory.snapshotAt),
          )
          .copyWith(source: CachedResourceSource.memory);
      _telemetry.onEvent(
        CacheFirstTelemetryEvent<T>(
          type: CacheFirstEventType.memoryHit,
          key: key,
          resource: resource,
        ),
      );
      return resource;
    }
    if (memory != null) {
      await memoryStore.clearScope(key);
    }

    final disk = await snapshotStore.read(key, allowStale: true);
    if (disk != null && _isCompatibleSchema(disk, schemaVersion)) {
      final resource = disk.toCachedResource(
        isStale: policy.isSnapshotStale(disk.snapshotAt),
      );
      await memoryStore.write(key, disk);
      _telemetry.onEvent(
        CacheFirstTelemetryEvent<T>(
          type: CacheFirstEventType.scopedSnapshotHit,
          key: key,
          resource: resource,
        ),
      );
      return resource;
    }
    if (disk != null) {
      await snapshotStore.clearScope(key);
    }

    if (policy.allowWarmLaunchFallback && loadWarmSnapshot != null) {
      final warmData = await loadWarmSnapshot();
      if (warmData != null) {
        final record = ScopedSnapshotRecord<T>(
          data: warmData,
          snapshotAt: DateTime.now(),
          schemaVersion: schemaVersion < 1 ? 1 : schemaVersion,
          generationId: 'warm:${DateTime.now().millisecondsSinceEpoch}',
          source: CachedResourceSource.warmLaunchPool,
        );
        await memoryStore.write(key, record);
        if (policy.persistWarmLaunchSnapshot) {
          await snapshotStore.write(key, record);
        }
        final resource = record.toCachedResource(
          isStale: policy.treatWarmLaunchAsStale,
        );
        _telemetry.onEvent(
          CacheFirstTelemetryEvent<T>(
            type: CacheFirstEventType.warmLaunchHit,
            key: key,
            resource: resource,
          ),
        );
        return resource;
      }
    }

    return CachedResource<T>.empty();
  }

  Future<CachedResource<T>> sync(
    ScopedSnapshotKey key, {
    required CachedResource<T> current,
    required CacheFirstLiveFetcher<T> fetchLive,
    CacheFirstIsEmpty<T>? isEmpty,
    CachedResourceSource liveSource = CachedResourceSource.server,
    int schemaVersion = 1,
    String? generationId,
  }) async {
    _telemetry.onEvent(
      CacheFirstTelemetryEvent<T>(
        type: CacheFirstEventType.liveSyncStarted,
        key: key,
        resource: current,
      ),
    );
    try {
      final liveData = await fetchLive();
      final liveIsEmpty = isEmpty?.call(liveData) ?? false;
      if (liveIsEmpty &&
          current.hasData &&
          policy.preservePreviousOnEmptyLive) {
        final preserved = current.copyWith(
          isRefreshing: false,
          isStale: true,
          hasLiveError: false,
          liveError: null,
          liveErrorStackTrace: null,
        );
        _telemetry.onEvent(
          CacheFirstTelemetryEvent<T>(
            type: CacheFirstEventType.liveSyncPreservedPrevious,
            key: key,
            resource: preserved,
          ),
        );
        return preserved;
      }

      final record = ScopedSnapshotRecord<T>(
        data: liveData,
        snapshotAt: DateTime.now(),
        schemaVersion: schemaVersion,
        generationId:
            generationId ?? DateTime.now().millisecondsSinceEpoch.toString(),
        source: liveSource,
      );
      await Future.wait(<Future<void>>[
        memoryStore.write(key, record),
        snapshotStore.write(key, record),
      ]);
      _lastLiveSyncAtByKey[key.storageKey] = record.snapshotAt;
      final resource = record.toCachedResource();
      _telemetry.onEvent(
        CacheFirstTelemetryEvent<T>(
          type: CacheFirstEventType.liveSyncSucceeded,
          key: key,
          resource: resource,
        ),
      );
      return resource;
    } catch (error, stackTrace) {
      final failed = current.markLiveError(error, stackTrace);
      _telemetry.onEvent(
        CacheFirstTelemetryEvent<T>(
          type: CacheFirstEventType.liveSyncFailed,
          key: key,
          resource: failed,
          error: error,
          stackTrace: stackTrace,
        ),
      );
      return failed;
    }
  }

  Future<void> clearScope(ScopedSnapshotKey key) async {
    await Future.wait(<Future<void>>[
      memoryStore.clearScope(key),
      snapshotStore.clearScope(key),
    ]);
    _lastLiveSyncAtByKey.remove(key.storageKey);
  }

  Future<void> clearSurface(
    String surfaceKey, {
    String? userId,
  }) async {
    await Future.wait(<Future<void>>[
      memoryStore.clearSurface(surfaceKey, userId: userId),
      snapshotStore.clearSurface(surfaceKey, userId: userId),
    ]);
    final normalizedSurface = surfaceKey.trim();
    final normalizedUser = (userId ?? '').trim();
    _lastLiveSyncAtByKey.removeWhere((storageKey, _) {
      final parts = storageKey.split('::');
      if (parts.isEmpty || parts.first != normalizedSurface) {
        return false;
      }
      if (normalizedUser.isEmpty) {
        return true;
      }
      return parts.length > 1 && parts[1] == normalizedUser;
    });
  }

  bool _shouldSync({
    required ScopedSnapshotKey key,
    required CachedResource<T> current,
    required bool forceSync,
  }) {
    if (forceSync) return true;
    if (!policy.syncOnOpen) return false;
    if (!current.hasData) return true;
    if (current.isStale) return true;
    return policy.canSyncAt(_lastLiveSyncAtByKey[key.storageKey]);
  }

  bool _isCompatibleSchema(
    ScopedSnapshotRecord<T> record,
    int expectedSchemaVersion,
  ) {
    final normalizedExpected =
        expectedSchemaVersion < 1 ? 1 : expectedSchemaVersion;
    return record.schemaVersion == normalizedExpected;
  }
}
