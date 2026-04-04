part of 'storage_budget_manager.dart';

StorageBudgetManager? maybeFindStorageBudgetManager() =>
    _maybeFindStorageBudgetManager();

StorageBudgetManager ensureStorageBudgetManager() =>
    _ensureStorageBudgetManager();

StorageBudgetUsageSnapshot storageBudgetUsageSnapshotForProfile(
  StorageBudgetProfile profile, {
  required int streamUsageBytes,
}) =>
    _storageUsageSnapshotForProfile(
      profile,
      streamUsageBytes: streamUsageBytes,
    );

int storageBudgetRecentProtectionWindowForUsage(
  StorageBudgetProfile profile, {
  required int streamUsageBytes,
  int remoteFloor = 3,
}) =>
    _storageRecentProtectionWindowForUsage(
      profile,
      streamUsageBytes: streamUsageBytes,
      remoteFloor: remoteFloor,
    );

StorageBudgetProfile storageBudgetProfileForPlanGb(int gb) =>
    _storageProfileForPlanGb(gb);

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
  final normalized = gb.clamp(3, 6);
  controller._selectedPlanGb.value = normalized;
  return storageBudgetProfileForPlanGb(normalized);
}

StorageBudgetUsageSnapshot _storageBudgetUsageSnapshot(
  StorageBudgetManager controller, {
  required int streamUsageBytes,
}) {
  return storageBudgetUsageSnapshotForProfile(
    controller.currentProfile,
    streamUsageBytes: streamUsageBytes,
  );
}

int _storageBudgetRecentProtectionWindow(
  StorageBudgetManager controller, {
  required int streamUsageBytes,
  int remoteFloor = 3,
}) {
  return storageBudgetRecentProtectionWindowForUsage(
    controller.currentProfile,
    streamUsageBytes: streamUsageBytes,
    remoteFloor: remoteFloor,
  );
}

extension StorageBudgetManagerFacadePart on StorageBudgetManager {
  int get selectedPlanGb => _selectedPlanGb.value;

  StorageBudgetProfile get currentProfile =>
      storageBudgetProfileForPlanGb(_selectedPlanGb.value);

  Future<StorageBudgetProfile> applyPlanGb(int gb) =>
      _applyStorageBudgetPlanGb(this, gb);

  StorageBudgetUsageSnapshot usageSnapshot({
    required int streamUsageBytes,
  }) =>
      _storageBudgetUsageSnapshot(
        this,
        streamUsageBytes: streamUsageBytes,
      );

  int recentProtectionWindow({
    required int streamUsageBytes,
    int remoteFloor = 3,
  }) =>
      _storageBudgetRecentProtectionWindow(
        this,
        streamUsageBytes: streamUsageBytes,
        remoteFloor: remoteFloor,
      );
}
