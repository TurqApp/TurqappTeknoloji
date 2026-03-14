import 'package:get/get.dart';

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

class StorageBudgetManager extends GetxService {
  static const int _mb = 1024 * 1024;
  final RxInt _selectedPlanGb = 3.obs;

  int get selectedPlanGb => _selectedPlanGb.value;
  StorageBudgetProfile get currentProfile =>
      profileForPlanGb(_selectedPlanGb.value);

  Future<StorageBudgetProfile> applyPlanGb(int gb) async {
    final normalized = gb.clamp(2, 5);
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

  static StorageBudgetUsageSnapshot usageSnapshotForProfile(
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

  static StorageBudgetProfile profileForPlanGb(int gb) {
    final normalized = gb.clamp(2, 5);
    final template = _templateFor(normalized);
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

  static _BudgetTemplate _templateFor(int planGb) {
    switch (planGb) {
      case 2:
        return const _BudgetTemplate(
          mediaQuotaBytes: 1370 * _mb,
          imageQuotaBytes: 220 * _mb,
          metadataQuotaBytes: 110 * _mb,
          reserveQuotaBytes: 120 * _mb,
          osSafetyMarginBytes: 180 * _mb,
        );
      case 3:
        return const _BudgetTemplate(
          mediaQuotaBytes: 2150 * _mb,
          imageQuotaBytes: 350 * _mb,
          metadataQuotaBytes: 180 * _mb,
          reserveQuotaBytes: 120 * _mb,
          osSafetyMarginBytes: 200 * _mb,
        );
      case 4:
        return const _BudgetTemplate(
          mediaQuotaBytes: 3000 * _mb,
          imageQuotaBytes: 420 * _mb,
          metadataQuotaBytes: 220 * _mb,
          reserveQuotaBytes: 160 * _mb,
          osSafetyMarginBytes: 200 * _mb,
        );
      default:
        return const _BudgetTemplate(
          mediaQuotaBytes: 3950 * _mb,
          imageQuotaBytes: 480 * _mb,
          metadataQuotaBytes: 250 * _mb,
          reserveQuotaBytes: 170 * _mb,
          osSafetyMarginBytes: 150 * _mb,
        );
    }
  }
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
