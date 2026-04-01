import 'package:flutter_test/flutter_test.dart';
import 'package:turqappv2/Core/Services/media_compression_service.dart';
import 'package:turqappv2/Core/Services/network_awareness_service.dart';
import 'package:turqappv2/Core/Services/upload_queue_service.dart';
import 'package:turqappv2/Runtime/feature_runtime_services.dart';

void main() {
  test('DeviceSessionRuntimeService delegates session claim', () {
    var claimedUid = '';
    final runtime = DeviceSessionRuntimeService(
      beginSessionClaimAction: (uid) => claimedUid = uid,
    );

    runtime.beginSessionClaim('user-42');

    expect(claimedUid, 'user-42');
  });

  test('NetworkRuntimeService delegates policy and diagnostics calls',
      () async {
    var ensured = false;
    var resetCalled = false;
    var trackedUploadMB = 0;
    var trackedDownloadMB = 0;
    NetworkSettings? updatedSettings;
    final settings = NetworkSettings(
      autoUploadOnWiFi: false,
      pauseOnCellular: true,
      cellularDataMode: DataUsageMode.low,
      wifiDataMode: DataUsageMode.normal,
      monthlyDataLimitMB: 2048,
      mobileTargetMbps: 7.5,
    );
    final usage = DataUsageStats(
      uploadedMB: 12,
      downloadedMB: 18,
      uploadedWifiMB: 8,
      downloadedWifiMB: 10,
      uploadedCellularMB: 4,
      downloadedCellularMB: 8,
      lastReset: DateTime(2026, 3, 1),
    );
    final runtime = NetworkRuntimeService(
      ensureReadyAction: () => ensured = true,
      isConnectedProvider: () => true,
      isOnWiFiProvider: () => false,
      isOnCellularProvider: () => true,
      settingsProvider: () => settings,
      dataUsageProvider: () => usage,
      networkStatsProvider: () => <String, dynamic>{
        'currentNetwork': 'cellular',
        'monthlyUsageMB': usage.totalMB,
      },
      shouldAllowUploadProvider: ({required fileSizeMB}) => fileSizeMB < 40,
      uploadRecommendationProvider: ({required fileSizeMB}) =>
          <String, dynamic>{
        'allowed': fileSizeMB < 40,
        'fileSizeMB': fileSizeMB,
      },
      compressionQualityProvider: () => CompressionQuality.medium,
      updateSettingsAction: (next) async => updatedSettings = next,
      resetDataUsageAction: () async => resetCalled = true,
      trackDataUsageAction: ({
        required int uploadMB,
        int downloadMB = 0,
      }) async {
        trackedUploadMB = uploadMB;
        trackedDownloadMB = downloadMB;
      },
    );

    runtime.ensureReady();

    expect(ensured, isTrue);
    expect(runtime.isConnected, isTrue);
    expect(runtime.isOnWiFi, isFalse);
    expect(runtime.isOnCellular, isTrue);
    expect(runtime.settings.pauseOnCellular, isTrue);
    expect(runtime.dataUsage.totalMB, 30);
    expect(runtime.getNetworkStats()['currentNetwork'], 'cellular');
    expect(runtime.shouldAllowUpload(fileSizeMB: 32), isTrue);
    expect(runtime.getUploadRecommendation(fileSizeMB: 64)['allowed'], isFalse);
    expect(
      runtime.getOptimalCompressionQuality(),
      CompressionQuality.medium,
    );

    final nextSettings = NetworkSettings(
      autoUploadOnWiFi: true,
      pauseOnCellular: false,
    );
    await runtime.updateSettings(nextSettings);
    await runtime.trackDataUsage(uploadMB: 12, downloadMB: 4);
    await runtime.resetDataUsage();

    expect(updatedSettings, same(nextSettings));
    expect(trackedUploadMB, 12);
    expect(trackedDownloadMB, 4);
    expect(resetCalled, isTrue);
  });

  test('UploadQueueRuntimeService delegates queue operations', () async {
    var ensuredPermanently = false;
    var processCalled = false;
    QueuedUpload? addedUpload;
    bool? addedStartProcessing;
    final runtime = UploadQueueRuntimeService(
      ensureReadyAction: ({bool permanent = false}) {
        ensuredPermanently = permanent;
      },
      addToQueueAction: (upload, {bool startProcessing = true}) async {
        addedUpload = upload;
        addedStartProcessing = startProcessing;
        return true;
      },
      processPendingQueueAction: () => processCalled = true,
      queueStatsProvider: () => <String, dynamic>{
        'pending': 3,
        'processing': false,
      },
    );
    final upload = QueuedUpload(
      id: 'queue-1',
      postData: '{"text":"hello"}',
      imagePaths: const <String>['/tmp/image.jpg'],
      createdAt: DateTime(2026, 3, 28),
    );

    runtime.ensureReady(permanent: true);
    final added = await runtime.addToQueue(upload, startProcessing: false);
    runtime.processPendingQueue();

    expect(ensuredPermanently, isTrue);
    expect(added, isTrue);
    expect(addedUpload, same(upload));
    expect(addedStartProcessing, isFalse);
    expect(runtime.getQueueStats()['pending'], 3);
    expect(processCalled, isTrue);
  });
}
