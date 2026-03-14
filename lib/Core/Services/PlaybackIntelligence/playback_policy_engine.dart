import 'package:get/get.dart';

import '../network_awareness_service.dart';
import 'storage_budget_manager.dart';

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

class PlaybackPolicyEngine extends GetxService {
  PlaybackPolicySnapshot snapshot({
    bool isBootstrap = false,
    int visibleReadyCount = 0,
    int visibleWindowCount = 0,
  }) {
    final network = Get.find<NetworkAwarenessService>();
    final budgetProfile = Get.isRegistered<StorageBudgetManager>()
        ? Get.find<StorageBudgetManager>().currentProfile
        : null;

    return resolve(
      PlaybackPolicyContext(
        isConnected: network.isConnected,
        isOnWiFi: network.isOnWiFi,
        isOnCellular: network.isOnCellular,
        pauseOnCellular: network.settings.pauseOnCellular,
        cellularDataMode: network.settings.cellularDataMode,
        wifiDataMode: network.settings.wifiDataMode,
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
