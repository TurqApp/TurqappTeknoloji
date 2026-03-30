import 'package:turqappv2/Core/Services/CacheFirst/cache_first_policy.dart';

class AdaptiveIntPolicy {
  const AdaptiveIntPolicy({
    required this.onWiFi,
    required this.onCellular,
  });

  const AdaptiveIntPolicy.uniform(int value)
      : onWiFi = value,
        onCellular = value;

  final int onWiFi;
  final int onCellular;

  int resolve({required bool onWiFi}) => onWiFi ? this.onWiFi : onCellular;
}

class LaunchAwareIntPolicy {
  const LaunchAwareIntPolicy({
    required this.wifiFirstLaunch,
    required this.wifiWarmLaunch,
    required this.cellularFirstLaunch,
    required this.cellularWarmLaunch,
  });

  final int wifiFirstLaunch;
  final int wifiWarmLaunch;
  final int cellularFirstLaunch;
  final int cellularWarmLaunch;

  int resolve({
    required bool onWiFi,
    required bool isFirstLaunch,
  }) {
    if (onWiFi) {
      return isFirstLaunch ? wifiFirstLaunch : wifiWarmLaunch;
    }
    return isFirstLaunch ? cellularFirstLaunch : cellularWarmLaunch;
  }

  List<int> additionalCandidates({required bool onWiFi}) => onWiFi
      ? <int>[wifiFirstLaunch, wifiWarmLaunch]
      : <int>[cellularFirstLaunch, cellularWarmLaunch];
}

class SurfacePolicy {
  const SurfacePolicy({
    this.schemaVersion = 1,
    this.cachePolicy = const CacheFirstPolicy(),
    this.initialLimit,
    this.searchLimit,
    this.pageLimit,
    this.fullLimit,
    this.startupShardLimit,
    this.readyForNavCount,
    this.initialPoolLimit,
    this.startupSnapshotLimit,
    this.warmTargetCount,
    this.backgroundWarmTargetCount,
    this.backgroundWarmMaxPages,
    this.startupWarmLimit,
    this.warmReadyTarget,
    this.startupPrefetchDocLimit,
    this.allowBackgroundRefreshOnWiFi = true,
    this.allowBackgroundRefreshOnCellular = false,
    this.bootstrapOnWiFi = true,
    this.bootstrapOnCellularWhenMissingLocal = true,
    this.bootstrapOnCellularWhenHasLocalContent = false,
  });

  final int schemaVersion;
  final CacheFirstPolicy cachePolicy;
  final int? initialLimit;
  final int? searchLimit;
  final int? pageLimit;
  final int? fullLimit;
  final AdaptiveIntPolicy? startupShardLimit;
  final int? readyForNavCount;
  final AdaptiveIntPolicy? initialPoolLimit;
  final LaunchAwareIntPolicy? startupSnapshotLimit;
  final LaunchAwareIntPolicy? warmTargetCount;
  final int? backgroundWarmTargetCount;
  final int? backgroundWarmMaxPages;
  final LaunchAwareIntPolicy? startupWarmLimit;
  final AdaptiveIntPolicy? warmReadyTarget;
  final int? startupPrefetchDocLimit;
  final bool allowBackgroundRefreshOnWiFi;
  final bool allowBackgroundRefreshOnCellular;
  final bool bootstrapOnWiFi;
  final bool bootstrapOnCellularWhenMissingLocal;
  final bool bootstrapOnCellularWhenHasLocalContent;

  int initialPoolLimitFor({required bool onWiFi}) {
    return initialPoolLimit?.resolve(onWiFi: onWiFi) ?? (initialLimit ?? 0);
  }

  int startupSnapshotLimitFor({
    required bool onWiFi,
    required bool isFirstLaunch,
  }) {
    return startupSnapshotLimit?.resolve(
          onWiFi: onWiFi,
          isFirstLaunch: isFirstLaunch,
        ) ??
        (initialLimit ?? 0);
  }

  List<int> startupSnapshotAdditionalLimits({required bool onWiFi}) {
    return startupSnapshotLimit?.additionalCandidates(onWiFi: onWiFi) ??
        const <int>[];
  }

  int warmTargetCountFor({
    required bool onWiFi,
    required bool isFirstLaunch,
  }) {
    return warmTargetCount?.resolve(
          onWiFi: onWiFi,
          isFirstLaunch: isFirstLaunch,
        ) ??
        startupSnapshotLimitFor(
          onWiFi: onWiFi,
          isFirstLaunch: isFirstLaunch,
        );
  }

  int startupWarmLimitFor({
    required bool onWiFi,
    required bool isFirstLaunch,
  }) {
    return startupWarmLimit?.resolve(
          onWiFi: onWiFi,
          isFirstLaunch: isFirstLaunch,
        ) ??
        (initialLimit ?? 0);
  }

  int warmReadyTargetFor({required bool onWiFi}) {
    return warmReadyTarget?.resolve(onWiFi: onWiFi) ?? (initialLimit ?? 0);
  }

  int startupShardLimitFor({required bool onWiFi}) {
    return startupShardLimit?.resolve(onWiFi: onWiFi) ?? 0;
  }

  bool allowBackgroundRefresh({required bool onWiFi}) {
    return onWiFi
        ? allowBackgroundRefreshOnWiFi
        : allowBackgroundRefreshOnCellular;
  }

  bool shouldBootstrapNetwork({
    required bool isConnected,
    required bool onWiFi,
    required bool hasLocalContent,
  }) {
    if (!isConnected) return false;
    if (onWiFi) return bootstrapOnWiFi;
    if (hasLocalContent) return bootstrapOnCellularWhenHasLocalContent;
    return bootstrapOnCellularWhenMissingLocal;
  }
}
