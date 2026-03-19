enum CachedResourceSource {
  none,
  memory,
  scopedDisk,
  warmLaunchPool,
  firestoreCache,
  server,
}

class CachedResource<T> {
  const CachedResource({
    required this.data,
    required this.hasLocalSnapshot,
    required this.isRefreshing,
    required this.isStale,
    required this.hasLiveError,
    required this.snapshotAt,
    required this.source,
    this.liveError,
    this.liveErrorStackTrace,
  });

  const CachedResource.empty({
    this.source = CachedResourceSource.none,
  })  : data = null,
        hasLocalSnapshot = false,
        isRefreshing = false,
        isStale = false,
        hasLiveError = false,
        snapshotAt = null,
        liveError = null,
        liveErrorStackTrace = null;

  final T? data;
  final bool hasLocalSnapshot;
  final bool isRefreshing;
  final bool isStale;
  final bool hasLiveError;
  final DateTime? snapshotAt;
  final CachedResourceSource source;
  final Object? liveError;
  final StackTrace? liveErrorStackTrace;

  bool get hasData => data != null;
  bool get isEmpty => data == null;

  CachedResource<T> copyWith({
    Object? data = _copySentinel,
    bool? hasLocalSnapshot,
    bool? isRefreshing,
    bool? isStale,
    bool? hasLiveError,
    Object? snapshotAt = _copySentinel,
    CachedResourceSource? source,
    Object? liveError = _copySentinel,
    Object? liveErrorStackTrace = _copySentinel,
  }) {
    return CachedResource<T>(
      data: identical(data, _copySentinel) ? this.data : data as T?,
      hasLocalSnapshot: hasLocalSnapshot ?? this.hasLocalSnapshot,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isStale: isStale ?? this.isStale,
      hasLiveError: hasLiveError ?? this.hasLiveError,
      snapshotAt: identical(snapshotAt, _copySentinel)
          ? this.snapshotAt
          : snapshotAt as DateTime?,
      source: source ?? this.source,
      liveError:
          identical(liveError, _copySentinel) ? this.liveError : liveError,
      liveErrorStackTrace: identical(liveErrorStackTrace, _copySentinel)
          ? this.liveErrorStackTrace
          : liveErrorStackTrace as StackTrace?,
    );
  }

  CachedResource<T> markRefreshing() {
    return copyWith(isRefreshing: true, hasLiveError: false);
  }

  CachedResource<T> markLiveError(
    Object error, [
    StackTrace? stackTrace,
  ]) {
    return copyWith(
      hasLiveError: true,
      isRefreshing: false,
      liveError: error,
      liveErrorStackTrace: stackTrace,
    );
  }
}

const Object _copySentinel = Object();
