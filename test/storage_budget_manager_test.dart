import 'package:flutter_test/flutter_test.dart';
import 'package:turqappv2/Core/Services/PlaybackIntelligence/metadata_read_policy.dart';
import 'package:turqappv2/Core/Services/PlaybackIntelligence/playback_policy_engine.dart';
import 'package:turqappv2/Core/Services/PlaybackIntelligence/storage_budget_manager.dart';
import 'package:turqappv2/Core/Services/network_awareness_service.dart';

void main() {
  test('storage budget profile exposes valid quota splits for 3 GB plan', () {
    final profile = StorageBudgetManager.profileForPlanGb(3);

    expect(profile.planGb, 3);
    expect(profile.mediaQuotaBytes, greaterThan(0));
    expect(profile.imageQuotaBytes, greaterThan(0));
    expect(profile.metadataQuotaBytes, greaterThan(0));
    expect(profile.reserveQuotaBytes, greaterThan(0));
    expect(profile.streamCacheHardStopBytes,
        greaterThan(profile.streamCacheSoftStopBytes));
    expect(profile.isValid, isTrue);
  });

  test('storage budget manager updates current profile when plan changes',
      () async {
    final manager = StorageBudgetManager();
    await manager.applyPlanGb(5);

    expect(manager.selectedPlanGb, 5);
    expect(manager.currentProfile.planGb, 5);
    expect(
      manager.currentProfile.streamCacheHardStopBytes,
      greaterThan(manager.currentProfile.streamCacheSoftStopBytes),
    );
  });

  test('storage budget usage snapshot reports ratios and remaining budget', () {
    final manager = StorageBudgetManager();
    final profile = StorageBudgetManager.profileForPlanGb(3);
    final snapshot = manager.usageSnapshot(
      streamUsageBytes: profile.streamCacheSoftStopBytes ~/ 2,
    );

    expect(snapshot.streamUsageBytes, profile.streamCacheSoftStopBytes ~/ 2);
    expect(snapshot.crossedSoftStop, isFalse);
    expect(snapshot.crossedHardStop, isFalse);
    expect(snapshot.remainingBeforeHardStopBytes, greaterThan(0));
    expect(snapshot.softUsageRatio, greaterThan(0));
  });

  test('playback policy resolves wifi fill mode with background prefetch', () {
    final snapshot = PlaybackPolicyEngine.resolve(
      const PlaybackPolicyContext(
        isConnected: true,
        isOnWiFi: true,
        isOnCellular: false,
        pauseOnCellular: false,
        cellularDataMode: DataUsageMode.low,
        wifiDataMode: DataUsageMode.high,
      ),
    );

    expect(snapshot.mode, PlaybackMode.wifiFill);
    expect(snapshot.policyTag, 'wifi_fill');
    expect(snapshot.allowBackgroundPrefetch, isTrue);
    expect(snapshot.allowOnDemandSegmentFetch, isTrue);
    expect(snapshot.startupWindowSegments, 2);
  });

  test('playback policy resolves cellular guard conservatively', () {
    final snapshot = PlaybackPolicyEngine.resolve(
      const PlaybackPolicyContext(
        isConnected: true,
        isOnWiFi: false,
        isOnCellular: true,
        pauseOnCellular: false,
        cellularDataMode: DataUsageMode.low,
        wifiDataMode: DataUsageMode.high,
      ),
    );

    expect(snapshot.mode, PlaybackMode.cellularGuard);
    expect(snapshot.policyTag, 'cellular_guard_low_data');
    expect(snapshot.allowBackgroundPrefetch, isFalse);
    expect(snapshot.allowOnDemandSegmentFetch, isTrue);
    expect(snapshot.startupWindowSegments, 1);
    expect(snapshot.aheadWindowSegments, 0);
  });

  test('playback policy enters cache-only cellular guard when paused by user',
      () {
    final snapshot = PlaybackPolicyEngine.resolve(
      const PlaybackPolicyContext(
        isConnected: true,
        isOnWiFi: false,
        isOnCellular: true,
        pauseOnCellular: true,
        cellularDataMode: DataUsageMode.low,
        wifiDataMode: DataUsageMode.high,
      ),
    );

    expect(snapshot.mode, PlaybackMode.cellularGuard);
    expect(snapshot.reason, 'cellular_paused_by_user');
    expect(snapshot.allowOnDemandSegmentFetch, isFalse);
    expect(snapshot.cacheOnlyMode, isTrue);
  });

  test('playback policy resolves offline guard with cache-only behavior', () {
    final snapshot = PlaybackPolicyEngine.resolve(
      const PlaybackPolicyContext(
        isConnected: false,
        isOnWiFi: false,
        isOnCellular: false,
        pauseOnCellular: false,
        cellularDataMode: DataUsageMode.low,
        wifiDataMode: DataUsageMode.high,
      ),
    );

    expect(snapshot.mode, PlaybackMode.offlineGuard);
    expect(snapshot.policyTag, 'offline_guard');
    expect(snapshot.allowBackgroundPrefetch, isFalse);
    expect(snapshot.allowOnDemandSegmentFetch, isFalse);
    expect(snapshot.cacheOnlyMode, isTrue);
  });

  test('metadata read policy keeps current user local-first by default', () {
    final decision = MetadataReadPolicy.currentUserSummary(
      preferCache: true,
      cacheOnly: false,
      forceServer: false,
    );

    expect(decision.readOrder.first, MetadataReadSource.memory);
    expect(decision.readOrder, contains(MetadataReadSource.sharedPrefs));
    expect(decision.readOrder.last, MetadataReadSource.server);
  });

  test('metadata read policy keeps user profile summary local-first', () {
    final decision = MetadataReadPolicy.userProfileSummary(
      preferCache: true,
      cacheOnly: false,
      forceServer: false,
    );

    expect(decision.readOrder.first, MetadataReadSource.memory);
    expect(decision.readOrder, contains(MetadataReadSource.firestoreCache));
    expect(decision.readOrder.last, MetadataReadSource.server);
  });
}
