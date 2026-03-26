part of 'storage_budget_manager.dart';

class StorageBudgetManager extends GetxService {
  static StorageBudgetManager? maybeFind() => _maybeFindStorageBudgetManager();

  static StorageBudgetManager ensure() => _ensureStorageBudgetManager();

  static const int _mb = 1024 * 1024;
  static const int _maxRecentProtectionWindow = 50;
  final _state = _StorageBudgetManagerState();

  int get selectedPlanGb => _selectedPlanGb.value;
  StorageBudgetProfile get currentProfile =>
      profileForPlanGb(_selectedPlanGb.value);

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

  static StorageBudgetUsageSnapshot usageSnapshotForProfile(
    StorageBudgetProfile profile, {
    required int streamUsageBytes,
  }) =>
      _storageUsageSnapshotForProfile(
        profile,
        streamUsageBytes: streamUsageBytes,
      );

  static int recentProtectionWindowForUsage(
    StorageBudgetProfile profile, {
    required int streamUsageBytes,
    int remoteFloor = 3,
  }) =>
      _storageRecentProtectionWindowForUsage(
        profile,
        streamUsageBytes: streamUsageBytes,
        remoteFloor: remoteFloor,
      );

  static StorageBudgetProfile profileForPlanGb(int gb) =>
      _storageProfileForPlanGb(gb);
}
