part of 'playback_policy_engine.dart';

enum PlaybackMode {
  bootstrap,
  wifiFill,
  cellularGuard,
  offlineGuard,
}

class PlaybackPolicyContext {
  final bool isConnected;
  final bool isOnWiFi;
  final bool isOnCellular;
  final bool pauseOnCellular;
  final DataUsageMode cellularDataMode;
  final DataUsageMode wifiDataMode;
  final bool isBootstrap;
  final int visibleReadyCount;
  final int visibleWindowCount;

  const PlaybackPolicyContext({
    required this.isConnected,
    required this.isOnWiFi,
    required this.isOnCellular,
    required this.pauseOnCellular,
    required this.cellularDataMode,
    required this.wifiDataMode,
    this.isBootstrap = false,
    this.visibleReadyCount = 0,
    this.visibleWindowCount = 0,
  });
}

class PlaybackPolicySnapshot {
  final PlaybackMode mode;
  final String policyTag;
  final String reason;
  final bool allowBackgroundPrefetch;
  final bool allowOnDemandSegmentFetch;
  final bool allowPlaylistFetch;
  final bool cacheOnlyMode;
  final bool enableMobileSeedMode;
  final int startupWindowSegments;
  final int aheadWindowSegments;
  final int maxConcurrentPrefetch;
  final StorageBudgetProfile? budgetProfile;

  const PlaybackPolicySnapshot({
    required this.mode,
    required this.policyTag,
    required this.reason,
    required this.allowBackgroundPrefetch,
    required this.allowOnDemandSegmentFetch,
    required this.allowPlaylistFetch,
    required this.cacheOnlyMode,
    required this.enableMobileSeedMode,
    required this.startupWindowSegments,
    required this.aheadWindowSegments,
    required this.maxConcurrentPrefetch,
    this.budgetProfile,
  });
}
