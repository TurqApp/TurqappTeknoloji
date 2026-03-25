import 'package:get/get.dart';

import '../network_awareness_service.dart';
import 'storage_budget_manager.dart';
part 'playback_policy_engine_models_part.dart';

class PlaybackPolicyEngine extends GetxService {
  static PlaybackPolicyEngine? maybeFind() {
    final isRegistered = Get.isRegistered<PlaybackPolicyEngine>();
    if (!isRegistered) return null;
    return Get.find<PlaybackPolicyEngine>();
  }

  static PlaybackPolicyEngine ensure() {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(PlaybackPolicyEngine(), permanent: true);
  }

  PlaybackPolicySnapshot snapshot({
    bool isBootstrap = false,
    int visibleReadyCount = 0,
    int visibleWindowCount = 0,
  }) {
    final network = NetworkAwarenessService.maybeFind();
    final budgetProfile = StorageBudgetManager.maybeFind()?.currentProfile;

    return resolve(
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

  static PlaybackPolicySnapshot resolve(
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
        mode: context.isBootstrap
            ? PlaybackMode.bootstrap
            : PlaybackMode.wifiFill,
        policyTag: context.isBootstrap ? 'bootstrap_wifi' : 'wifi_fill',
        reason:
            context.isBootstrap ? 'startup_connected_wifi' : 'wifi_available',
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

    final lowData = context.cellularDataMode == DataUsageMode.low ||
        context.pauseOnCellular;

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
      enableMobileSeedMode: false,
      startupWindowSegments: lowData ? 1 : 2,
      aheadWindowSegments: lowData ? 0 : 1,
      maxConcurrentPrefetch: 1,
      budgetProfile: budgetProfile,
    );
  }
}
