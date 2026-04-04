part of 'storage_budget_manager.dart';

StorageBudgetUsageSnapshot _storageUsageSnapshotForProfile(
  StorageBudgetProfile profile, {
  required int streamUsageBytes,
}) {
  final normalizedUsage = streamUsageBytes < 0 ? 0 : streamUsageBytes;
  final remainingSoft =
      (profile.streamCacheSoftStopBytes - normalizedUsage).clamp(
    0,
    profile.streamCacheSoftStopBytes,
  );
  final remainingHard =
      (profile.streamCacheHardStopBytes - normalizedUsage).clamp(
    0,
    profile.streamCacheHardStopBytes,
  );

  return StorageBudgetUsageSnapshot(
    profile: profile,
    streamUsageBytes: normalizedUsage,
    remainingBeforeSoftStopBytes: remainingSoft,
    remainingBeforeHardStopBytes: remainingHard,
    softUsageRatio:
        (normalizedUsage / profile.streamCacheSoftStopBytes).clamp(0.0, 1.0),
    hardUsageRatio:
        (normalizedUsage / profile.streamCacheHardStopBytes).clamp(0.0, 1.0),
    crossedSoftStop: normalizedUsage >= profile.streamCacheSoftStopBytes,
    crossedHardStop: normalizedUsage >= profile.streamCacheHardStopBytes,
  );
}

int _storageRecentProtectionWindowForUsage(
  StorageBudgetProfile profile, {
  required int streamUsageBytes,
  int remoteFloor = 3,
}) {
  final minWindow =
      remoteFloor.clamp(1, StorageBudgetManager._maxRecentProtectionWindow);
  final baseWindow = _storageBaseRecentProtectionWindow(profile.planGb);
  final snapshot = _storageUsageSnapshotForProfile(
    profile,
    streamUsageBytes: streamUsageBytes,
  );

  if (snapshot.crossedHardStop) {
    return minWindow;
  }
  if (snapshot.crossedSoftStop) {
    return _storageScaledWindow(baseWindow, 0.18, minWindow);
  }
  if (snapshot.softUsageRatio >= 0.92) {
    return _storageScaledWindow(baseWindow, 0.32, minWindow);
  }
  if (snapshot.softUsageRatio >= 0.82) {
    return _storageScaledWindow(baseWindow, 0.50, minWindow);
  }
  if (snapshot.softUsageRatio >= 0.70) {
    return _storageScaledWindow(baseWindow, 0.72, minWindow);
  }

  return baseWindow.clamp(
      minWindow, StorageBudgetManager._maxRecentProtectionWindow);
}

StorageBudgetProfile _storageProfileForPlanGb(int gb) {
  final normalized = gb.clamp(3, 6);
  final template = _storageTemplateFor(normalized);
  final mediaSoftStopBytes = template.mediaQuotaBytes;
  final mediaHardStopBytes =
      mediaSoftStopBytes + (template.mediaQuotaBytes ~/ 10);

  return StorageBudgetProfile(
    planGb: normalized,
    totalPlanBytes: (normalized + 1) * 1024 * 1024 * 1024,
    mediaQuotaBytes: template.mediaQuotaBytes,
    imageQuotaBytes: template.imageQuotaBytes,
    metadataQuotaBytes: template.metadataQuotaBytes,
    reserveQuotaBytes: template.reserveQuotaBytes,
    osSafetyMarginBytes: template.osSafetyMarginBytes,
    streamCacheSoftStopBytes: mediaSoftStopBytes,
    streamCacheHardStopBytes: mediaHardStopBytes,
  );
}

int _storageBaseRecentProtectionWindow(int planGb) {
  switch (planGb.clamp(3, 6)) {
    case 3:
      return 32;
    case 4:
      return 42;
    case 5:
      return 46;
    default:
      return StorageBudgetManager._maxRecentProtectionWindow;
  }
}

int _storageScaledWindow(int base, double factor, int minWindow) {
  final scaled = (base * factor).round();
  return scaled.clamp(
      minWindow, StorageBudgetManager._maxRecentProtectionWindow);
}

_BudgetTemplate _storageTemplateFor(int planGb) {
  switch (planGb) {
    case 3:
      return const _BudgetTemplate(
        mediaQuotaBytes: 3072 * StorageBudgetManager._mb,
        imageQuotaBytes: 512 * StorageBudgetManager._mb,
        metadataQuotaBytes: 0,
        reserveQuotaBytes: 256 * StorageBudgetManager._mb,
        osSafetyMarginBytes: 256 * StorageBudgetManager._mb,
      );
    case 4:
      return const _BudgetTemplate(
        mediaQuotaBytes: 4096 * StorageBudgetManager._mb,
        imageQuotaBytes: 512 * StorageBudgetManager._mb,
        metadataQuotaBytes: 0,
        reserveQuotaBytes: 256 * StorageBudgetManager._mb,
        osSafetyMarginBytes: 256 * StorageBudgetManager._mb,
      );
    case 5:
      return const _BudgetTemplate(
        mediaQuotaBytes: 5120 * StorageBudgetManager._mb,
        imageQuotaBytes: 512 * StorageBudgetManager._mb,
        metadataQuotaBytes: 0,
        reserveQuotaBytes: 256 * StorageBudgetManager._mb,
        osSafetyMarginBytes: 256 * StorageBudgetManager._mb,
      );
    default:
      return const _BudgetTemplate(
        mediaQuotaBytes: 6144 * StorageBudgetManager._mb,
        imageQuotaBytes: 512 * StorageBudgetManager._mb,
        metadataQuotaBytes: 0,
        reserveQuotaBytes: 256 * StorageBudgetManager._mb,
        osSafetyMarginBytes: 256 * StorageBudgetManager._mb,
      );
  }
}
