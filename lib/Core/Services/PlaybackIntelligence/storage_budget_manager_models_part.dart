part of 'storage_budget_manager.dart';

class StorageBudgetProfile {
  final int planGb;
  final int totalPlanBytes;
  final int mediaQuotaBytes;
  final int imageQuotaBytes;
  final int metadataQuotaBytes;
  final int reserveQuotaBytes;
  final int osSafetyMarginBytes;
  final int streamCacheSoftStopBytes;
  final int streamCacheHardStopBytes;

  const StorageBudgetProfile({
    required this.planGb,
    required this.totalPlanBytes,
    required this.mediaQuotaBytes,
    required this.imageQuotaBytes,
    required this.metadataQuotaBytes,
    required this.reserveQuotaBytes,
    required this.osSafetyMarginBytes,
    required this.streamCacheSoftStopBytes,
    required this.streamCacheHardStopBytes,
  });

  bool get isValid =>
      streamCacheSoftStopBytes > 0 &&
      streamCacheHardStopBytes >= streamCacheSoftStopBytes &&
      totalPlanBytes > 0;

  Map<String, dynamic> toJson() => {
        'planGb': planGb,
        'totalPlanBytes': totalPlanBytes,
        'mediaQuotaBytes': mediaQuotaBytes,
        'imageQuotaBytes': imageQuotaBytes,
        'metadataQuotaBytes': metadataQuotaBytes,
        'reserveQuotaBytes': reserveQuotaBytes,
        'osSafetyMarginBytes': osSafetyMarginBytes,
        'streamCacheSoftStopBytes': streamCacheSoftStopBytes,
        'streamCacheHardStopBytes': streamCacheHardStopBytes,
      };
}

class StorageBudgetUsageSnapshot {
  final StorageBudgetProfile profile;
  final int streamUsageBytes;
  final int remainingBeforeSoftStopBytes;
  final int remainingBeforeHardStopBytes;
  final double softUsageRatio;
  final double hardUsageRatio;
  final bool crossedSoftStop;
  final bool crossedHardStop;

  const StorageBudgetUsageSnapshot({
    required this.profile,
    required this.streamUsageBytes,
    required this.remainingBeforeSoftStopBytes,
    required this.remainingBeforeHardStopBytes,
    required this.softUsageRatio,
    required this.hardUsageRatio,
    required this.crossedSoftStop,
    required this.crossedHardStop,
  });
}

class _BudgetTemplate {
  final int mediaQuotaBytes;
  final int imageQuotaBytes;
  final int metadataQuotaBytes;
  final int reserveQuotaBytes;
  final int osSafetyMarginBytes;

  const _BudgetTemplate({
    required this.mediaQuotaBytes,
    required this.imageQuotaBytes,
    required this.metadataQuotaBytes,
    required this.reserveQuotaBytes,
    required this.osSafetyMarginBytes,
  });
}
