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
  final normalized = gb.clamp(4, 7);
  final template = _storageTemplateFor(normalized);
  final mediaHardStopBytes =
      template.mediaQuotaBytes + template.reserveQuotaBytes;
  final mediaSoftStopBytes = (mediaHardStopBytes * 0.90).round();

  return StorageBudgetProfile(
    planGb: normalized,
    totalPlanBytes: normalized * 1024 * 1024 * 1024,
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
  switch (planGb.clamp(4, 7)) {
    case 4:
      return 32;
    case 5:
      return 42;
    case 6:
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
    case 4:
      return const _BudgetTemplate(
        mediaQuotaBytes: 3000 * StorageBudgetManager._mb,
        imageQuotaBytes: 420 * StorageBudgetManager._mb,
        metadataQuotaBytes: 220 * StorageBudgetManager._mb,
        reserveQuotaBytes: 160 * StorageBudgetManager._mb,
        osSafetyMarginBytes: 200 * StorageBudgetManager._mb,
      );
    case 5:
      return const _BudgetTemplate(
        mediaQuotaBytes: 3950 * StorageBudgetManager._mb,
        imageQuotaBytes: 480 * StorageBudgetManager._mb,
        metadataQuotaBytes: 250 * StorageBudgetManager._mb,
        reserveQuotaBytes: 170 * StorageBudgetManager._mb,
        osSafetyMarginBytes: 150 * StorageBudgetManager._mb,
      );
    case 6:
      return const _BudgetTemplate(
        mediaQuotaBytes: 4900 * StorageBudgetManager._mb,
        imageQuotaBytes: 560 * StorageBudgetManager._mb,
        metadataQuotaBytes: 280 * StorageBudgetManager._mb,
        reserveQuotaBytes: 190 * StorageBudgetManager._mb,
        osSafetyMarginBytes: 170 * StorageBudgetManager._mb,
      );
    default:
      return const _BudgetTemplate(
        mediaQuotaBytes: 5850 * StorageBudgetManager._mb,
        imageQuotaBytes: 640 * StorageBudgetManager._mb,
        metadataQuotaBytes: 320 * StorageBudgetManager._mb,
        reserveQuotaBytes: 210 * StorageBudgetManager._mb,
        osSafetyMarginBytes: 180 * StorageBudgetManager._mb,
      );
  }
}
