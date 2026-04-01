part of 'playback_policy_engine.dart';

PlaybackPolicyEngine? maybeFindPlaybackPolicyEngine() {
  final isRegistered = Get.isRegistered<PlaybackPolicyEngine>();
  if (!isRegistered) return null;
  return Get.find<PlaybackPolicyEngine>();
}

PlaybackPolicyEngine ensurePlaybackPolicyEngine() {
  final existing = maybeFindPlaybackPolicyEngine();
  if (existing != null) return existing;
  return Get.put(PlaybackPolicyEngine(), permanent: true);
}

PlaybackPolicySnapshot resolvePlaybackPolicySnapshot(
  PlaybackPolicyContext context, {
  StorageBudgetProfile? budgetProfile,
}) =>
    _resolvePlaybackPolicy(
      context,
      budgetProfile: budgetProfile,
    );

extension PlaybackPolicyEngineFacadePart on PlaybackPolicyEngine {
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
}
