import 'package:turqappv2/Core/Services/media_compression_service.dart';
import 'package:turqappv2/Core/Services/network_awareness_service.dart';
import 'package:turqappv2/Core/Services/upload_queue_service.dart';
import 'package:turqappv2/Services/device_session_service.dart';

typedef DeviceSessionClaimAction = void Function(String uid);
typedef NetworkReadyAction = void Function();
typedef NetworkBoolProvider = bool Function();
typedef NetworkSettingsProvider = NetworkSettings Function();
typedef DataUsageProvider = DataUsageStats Function();
typedef NetworkStatsProvider = Map<String, dynamic> Function();
typedef UploadPolicyProvider = bool Function({required int fileSizeMB});
typedef UploadRecommendationProvider = Map<String, dynamic> Function({
  required int fileSizeMB,
});
typedef CompressionQualityProvider = CompressionQuality Function();
typedef NetworkSettingsUpdateAction = Future<void> Function(
  NetworkSettings settings,
);
typedef ResetDataUsageAction = Future<void> Function();
typedef TrackDataUsageAction = Future<void> Function({
  required int uploadMB,
  int downloadMB,
});
typedef UploadQueueEnsureAction = void Function({bool permanent});
typedef UploadQueueAddAction = Future<bool> Function(
  QueuedUpload upload, {
  bool startProcessing,
});
typedef UploadQueueProcessAction = void Function();
typedef UploadQueueStatsProvider = Map<String, dynamic> Function();

class DeviceSessionRuntimeService {
  const DeviceSessionRuntimeService({
    this.beginSessionClaimAction,
  });

  final DeviceSessionClaimAction? beginSessionClaimAction;

  void beginSessionClaim(String uid) {
    final action = beginSessionClaimAction;
    if (action != null) {
      action(uid);
      return;
    }
    DeviceSessionService.instance.beginSessionClaim(uid);
  }
}

class NetworkRuntimeService {
  const NetworkRuntimeService({
    this.ensureReadyAction,
    this.isConnectedProvider,
    this.isOnWiFiProvider,
    this.isOnCellularProvider,
    this.settingsProvider,
    this.dataUsageProvider,
    this.networkStatsProvider,
    this.shouldAllowUploadProvider,
    this.uploadRecommendationProvider,
    this.compressionQualityProvider,
    this.updateSettingsAction,
    this.resetDataUsageAction,
    this.trackDataUsageAction,
  });

  final NetworkReadyAction? ensureReadyAction;
  final NetworkBoolProvider? isConnectedProvider;
  final NetworkBoolProvider? isOnWiFiProvider;
  final NetworkBoolProvider? isOnCellularProvider;
  final NetworkSettingsProvider? settingsProvider;
  final DataUsageProvider? dataUsageProvider;
  final NetworkStatsProvider? networkStatsProvider;
  final UploadPolicyProvider? shouldAllowUploadProvider;
  final UploadRecommendationProvider? uploadRecommendationProvider;
  final CompressionQualityProvider? compressionQualityProvider;
  final NetworkSettingsUpdateAction? updateSettingsAction;
  final ResetDataUsageAction? resetDataUsageAction;
  final TrackDataUsageAction? trackDataUsageAction;

  void ensureReady() {
    final action = ensureReadyAction;
    if (action != null) {
      action();
      return;
    }
    NetworkAwarenessService.ensure();
  }

  bool get isConnected {
    final provider = isConnectedProvider;
    if (provider != null) {
      return provider();
    }
    return NetworkAwarenessService.ensure().isConnected;
  }

  bool get isOnWiFi {
    final provider = isOnWiFiProvider;
    if (provider != null) {
      return provider();
    }
    return NetworkAwarenessService.ensure().isOnWiFi;
  }

  bool get isOnCellular {
    final provider = isOnCellularProvider;
    if (provider != null) {
      return provider();
    }
    return NetworkAwarenessService.ensure().isOnCellular;
  }

  NetworkSettings get settings {
    final provider = settingsProvider;
    if (provider != null) {
      return provider();
    }
    return NetworkAwarenessService.ensure().settings;
  }

  DataUsageStats get dataUsage {
    final provider = dataUsageProvider;
    if (provider != null) {
      return provider();
    }
    return NetworkAwarenessService.ensure().dataUsage;
  }

  Map<String, dynamic> getNetworkStats() {
    final provider = networkStatsProvider;
    if (provider != null) {
      return provider();
    }
    return NetworkAwarenessService.ensure().getNetworkStats();
  }

  bool shouldAllowUpload({required int fileSizeMB}) {
    final provider = shouldAllowUploadProvider;
    if (provider != null) {
      return provider(fileSizeMB: fileSizeMB);
    }
    return NetworkAwarenessService.ensure().shouldAllowUpload(
      fileSizeMB: fileSizeMB,
    );
  }

  Map<String, dynamic> getUploadRecommendation({required int fileSizeMB}) {
    final provider = uploadRecommendationProvider;
    if (provider != null) {
      return provider(fileSizeMB: fileSizeMB);
    }
    return NetworkAwarenessService.ensure().getUploadRecommendation(
      fileSizeMB: fileSizeMB,
    );
  }

  CompressionQuality getOptimalCompressionQuality() {
    final provider = compressionQualityProvider;
    if (provider != null) {
      return provider();
    }
    return NetworkAwarenessService.ensure().getOptimalCompressionQuality();
  }

  Future<void> updateSettings(NetworkSettings settings) async {
    final action = updateSettingsAction;
    if (action != null) {
      await action(settings);
      return;
    }
    await NetworkAwarenessService.ensure().updateSettings(settings);
  }

  Future<void> resetDataUsage() async {
    final action = resetDataUsageAction;
    if (action != null) {
      await action();
      return;
    }
    await NetworkAwarenessService.ensure().resetDataUsage();
  }

  Future<void> trackDataUsage({
    required int uploadMB,
    int downloadMB = 0,
  }) async {
    final action = trackDataUsageAction;
    if (action != null) {
      await action(
        uploadMB: uploadMB,
        downloadMB: downloadMB,
      );
      return;
    }
    await NetworkAwarenessService.ensure().trackDataUsage(
      uploadMB: uploadMB,
      downloadMB: downloadMB,
    );
  }
}

class UploadQueueRuntimeService {
  const UploadQueueRuntimeService({
    this.ensureReadyAction,
    this.addToQueueAction,
    this.processPendingQueueAction,
    this.queueStatsProvider,
  });

  final UploadQueueEnsureAction? ensureReadyAction;
  final UploadQueueAddAction? addToQueueAction;
  final UploadQueueProcessAction? processPendingQueueAction;
  final UploadQueueStatsProvider? queueStatsProvider;

  void ensureReady({bool permanent = false}) {
    final action = ensureReadyAction;
    if (action != null) {
      action(permanent: permanent);
      return;
    }
    UploadQueueService.ensure(permanent: permanent);
  }

  Future<bool> addToQueue(
    QueuedUpload upload, {
    bool startProcessing = true,
  }) async {
    final action = addToQueueAction;
    if (action != null) {
      return action(upload, startProcessing: startProcessing);
    }
    return UploadQueueService.ensure().addToQueue(
      upload,
      startProcessing: startProcessing,
    );
  }

  void processPendingQueue() {
    final action = processPendingQueueAction;
    if (action != null) {
      action();
      return;
    }
    UploadQueueService.ensure().processPendingQueue();
  }

  Map<String, dynamic> getQueueStats() {
    final provider = queueStatsProvider;
    if (provider != null) {
      return provider();
    }
    return UploadQueueService.ensure().getQueueStats();
  }
}
