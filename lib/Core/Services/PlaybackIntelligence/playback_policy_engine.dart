import 'package:get/get.dart';

import '../network_awareness_service.dart';
import 'storage_budget_manager.dart';
part 'playback_policy_engine_models_part.dart';
part 'playback_policy_engine_runtime_part.dart';

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
  }) =>
      _snapshotPlaybackPolicy(
        isBootstrap: isBootstrap,
        visibleReadyCount: visibleReadyCount,
        visibleWindowCount: visibleWindowCount,
      );

  static PlaybackPolicySnapshot resolve(
    PlaybackPolicyContext context, {
    StorageBudgetProfile? budgetProfile,
  }) =>
      _resolvePlaybackPolicy(
        context,
        budgetProfile: budgetProfile,
      );
}
