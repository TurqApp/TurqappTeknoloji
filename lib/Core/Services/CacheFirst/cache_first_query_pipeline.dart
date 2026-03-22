import 'dart:async';

import 'cache_first_coordinator.dart';
import 'cached_resource.dart';
import 'scoped_snapshot_store.dart';

typedef CacheFirstScopeIdBuilder<TQuery> = String Function(TQuery query);
typedef CacheFirstUserIdResolver<TQuery> = String Function(TQuery query);
typedef CacheFirstRawFetcher<TQuery, TRaw> = Future<TRaw> Function(TQuery query);
typedef CacheFirstResolver<TRaw, TResolved> = FutureOr<TResolved> Function(
  TRaw raw,
);
typedef CacheFirstWarmQueryReader<TQuery, TResolved> = Future<TResolved?> Function(
  TQuery query,
);
typedef CacheFirstResolvedIsEmpty<TResolved> = bool Function(TResolved value);

class CacheFirstQueryPipeline<TQuery, TRaw, TResolved> {
  CacheFirstQueryPipeline({
    required this.surfaceKey,
    required this.coordinator,
    required this.scopeIdBuilder,
    required this.fetchRaw,
    required this.resolve,
    this.userIdResolver,
    this.loadWarmSnapshot,
    this.isEmpty,
    this.liveSource = CachedResourceSource.server,
    this.schemaVersion = 1,
  });

  final String surfaceKey;
  final CacheFirstCoordinator<TResolved> coordinator;
  final CacheFirstScopeIdBuilder<TQuery> scopeIdBuilder;
  final CacheFirstRawFetcher<TQuery, TRaw> fetchRaw;
  final CacheFirstResolver<TRaw, TResolved> resolve;
  final CacheFirstUserIdResolver<TQuery>? userIdResolver;
  final CacheFirstWarmQueryReader<TQuery, TResolved>? loadWarmSnapshot;
  final CacheFirstResolvedIsEmpty<TResolved>? isEmpty;
  final CachedResourceSource liveSource;
  final int schemaVersion;

  Stream<CachedResource<TResolved>> open(
    TQuery query, {
    bool forceSync = false,
  }) {
    final key = ScopedSnapshotKey(
      surfaceKey: surfaceKey,
      userId: userIdResolver?.call(query) ?? '',
      scopeId: scopeIdBuilder(query),
    );
    return coordinator.open(
      key,
      forceSync: forceSync,
      loadWarmSnapshot: loadWarmSnapshot == null
          ? null
          : () => loadWarmSnapshot!(query),
      isEmpty: isEmpty,
      liveSource: liveSource,
      schemaVersion: schemaVersion,
      fetchLive: () async {
        final raw = await fetchRaw(query);
        return await resolve(raw);
      },
    );
  }
}

