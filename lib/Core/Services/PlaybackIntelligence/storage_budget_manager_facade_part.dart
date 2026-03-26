part of 'storage_budget_manager.dart';

StorageBudgetManager? _maybeFindStorageBudgetManager() {
  final isRegistered = Get.isRegistered<StorageBudgetManager>();
  if (!isRegistered) return null;
  return Get.find<StorageBudgetManager>();
}

StorageBudgetManager _ensureStorageBudgetManager() {
  final existing = _maybeFindStorageBudgetManager();
  if (existing != null) return existing;
  return Get.put(StorageBudgetManager(), permanent: true);
}

Future<StorageBudgetProfile> _applyStorageBudgetPlanGb(
  StorageBudgetManager controller,
  int gb,
) async {
  final normalized = gb.clamp(4, 7);
  controller._selectedPlanGb.value = normalized;
  return StorageBudgetManager.profileForPlanGb(normalized);
}

StorageBudgetUsageSnapshot _storageBudgetUsageSnapshot(
  StorageBudgetManager controller, {
  required int streamUsageBytes,
}) {
  return StorageBudgetManager.usageSnapshotForProfile(
    controller.currentProfile,
    streamUsageBytes: streamUsageBytes,
  );
}

int _storageBudgetRecentProtectionWindow(
  StorageBudgetManager controller, {
  required int streamUsageBytes,
  int remoteFloor = 3,
}) {
  return StorageBudgetManager.recentProtectionWindowForUsage(
    controller.currentProfile,
    streamUsageBytes: streamUsageBytes,
    remoteFloor: remoteFloor,
  );
}
