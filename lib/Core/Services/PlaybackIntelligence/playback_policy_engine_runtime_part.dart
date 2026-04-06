part of 'playback_policy_engine.dart';

PlaybackPolicySnapshot _snapshotPlaybackPolicy({
  required bool isBootstrap,
  required int visibleReadyCount,
  required int visibleWindowCount,
}) {
  final network = NetworkAwarenessService.maybeFind();
  final budgetProfile = StorageBudgetManager.maybeFind()?.currentProfile;

  return resolvePlaybackPolicySnapshot(
    PlaybackPolicyContext(
      isConnected: network?.isConnected ?? false,
      isOnWiFi: network?.isOnWiFi ?? false,
      isOnCellular: network?.isOnCellular ?? false,
      pauseOnCellular: network?.settings.pauseOnCellular ?? false,
      cellularDataMode:
          network?.settings.cellularDataMode ?? DataUsageMode.normal,
      wifiDataMode: network?.settings.wifiDataMode ?? DataUsageMode.normal,
      isBootstrap: isBootstrap,
      visibleReadyCount: visibleReadyCount,
      visibleWindowCount: visibleWindowCount,
    ),
    budgetProfile: budgetProfile,
  );
}

PlaybackPolicySnapshot _resolvePlaybackPolicy(
  PlaybackPolicyContext context, {
  StorageBudgetProfile? budgetProfile,
}) {
  if (!context.isConnected) {
    return PlaybackPolicySnapshot(
      mode: PlaybackMode.offlineGuard,
      policyTag: 'offline_guard',
      reason: 'network_disconnected',
      allowBackgroundPrefetch: false,
      allowOnDemandSegmentFetch: false,
      allowPlaylistFetch: false,
      cacheOnlyMode: true,
      enableMobileSeedMode: false,
      startupWindowSegments: 0,
      aheadWindowSegments: 0,
      maxConcurrentPrefetch: 0,
      budgetProfile: budgetProfile,
    );
  }

  if (context.isOnWiFi) {
    return PlaybackPolicySnapshot(
      mode:
          context.isBootstrap ? PlaybackMode.bootstrap : PlaybackMode.wifiFill,
      policyTag: context.isBootstrap ? 'bootstrap_wifi' : 'wifi_fill',
      reason: context.isBootstrap ? 'startup_connected_wifi' : 'wifi_available',
      allowBackgroundPrefetch: true,
      allowOnDemandSegmentFetch: true,
      allowPlaylistFetch: true,
      cacheOnlyMode: false,
      enableMobileSeedMode: false,
      startupWindowSegments: 2,
      aheadWindowSegments: context.isBootstrap ? 1 : 2,
      maxConcurrentPrefetch: 4,
      budgetProfile: budgetProfile,
    );
  }

  final lowData =
      context.cellularDataMode == DataUsageMode.low || context.pauseOnCellular;

  return PlaybackPolicySnapshot(
    mode: PlaybackMode.cellularGuard,
    policyTag: lowData ? 'cellular_guard_low_data' : 'cellular_guard',
    reason: context.pauseOnCellular
        ? 'cellular_paused_by_user'
        : lowData
            ? 'cellular_low_data_mode'
            : 'cellular_connected',
    allowBackgroundPrefetch: false,
    allowOnDemandSegmentFetch: !context.pauseOnCellular,
    allowPlaylistFetch: true,
    cacheOnlyMode: context.pauseOnCellular,
    enableMobileSeedMode: !lowData,
    startupWindowSegments: lowData ? 1 : 2,
    aheadWindowSegments: lowData ? 0 : 1,
    maxConcurrentPrefetch: 1,
    budgetProfile: budgetProfile,
  );
}
