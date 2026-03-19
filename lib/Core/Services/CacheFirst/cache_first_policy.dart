class CacheFirstPolicy {
  const CacheFirstPolicy({
    this.snapshotTtl = const Duration(minutes: 15),
    this.minLiveSyncInterval = const Duration(seconds: 30),
    this.syncOnOpen = true,
    this.allowWarmLaunchFallback = true,
    this.persistWarmLaunchSnapshot = false,
    this.treatWarmLaunchAsStale = true,
    this.preservePreviousOnEmptyLive = true,
  });

  final Duration snapshotTtl;
  final Duration minLiveSyncInterval;
  final bool syncOnOpen;
  final bool allowWarmLaunchFallback;
  final bool persistWarmLaunchSnapshot;
  final bool treatWarmLaunchAsStale;
  final bool preservePreviousOnEmptyLive;

  bool isSnapshotStale(DateTime snapshotAt) {
    return DateTime.now().difference(snapshotAt) > snapshotTtl;
  }

  bool canSyncAt(DateTime? lastLiveSyncAt) {
    if (lastLiveSyncAt == null) return true;
    return DateTime.now().difference(lastLiveSyncAt) >= minLiveSyncInterval;
  }
}

