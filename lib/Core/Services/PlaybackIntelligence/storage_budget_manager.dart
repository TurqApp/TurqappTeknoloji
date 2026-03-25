import 'package:get/get.dart';

part 'storage_budget_manager_models_part.dart';
part 'storage_budget_manager_runtime_part.dart';

class StorageBudgetManager extends GetxService {
  static StorageBudgetManager? maybeFind() {
    final isRegistered = Get.isRegistered<StorageBudgetManager>();
    if (!isRegistered) return null;
    return Get.find<StorageBudgetManager>();
  }

  static StorageBudgetManager ensure() {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(StorageBudgetManager(), permanent: true);
  }

  static const int _mb = 1024 * 1024;
  static const int _maxRecentProtectionWindow = 50;
  final RxInt _selectedPlanGb = 4.obs;

  int get selectedPlanGb => _selectedPlanGb.value;
  StorageBudgetProfile get currentProfile =>
      profileForPlanGb(_selectedPlanGb.value);

  Future<StorageBudgetProfile> applyPlanGb(int gb) async {
    final normalized = gb.clamp(4, 7);
    _selectedPlanGb.value = normalized;
    return profileForPlanGb(normalized);
  }

  StorageBudgetUsageSnapshot usageSnapshot({
    required int streamUsageBytes,
  }) {
    return usageSnapshotForProfile(
      currentProfile,
      streamUsageBytes: streamUsageBytes,
    );
  }

  int recentProtectionWindow({
    required int streamUsageBytes,
    int remoteFloor = 3,
  }) {
    return recentProtectionWindowForUsage(
      currentProfile,
      streamUsageBytes: streamUsageBytes,
      remoteFloor: remoteFloor,
    );
  }

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
