import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turqappv2/Core/Services/video_telemetry_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  tearDown(Get.reset);

  test('video telemetry snapshot reflects runtime hints', () async {
    const videoId = 'telemetry_test_video';
    const videoUrl = 'https://cdn.example.com/test.m3u8';

    VideoTelemetryService.instance.startSession(videoId, videoUrl);
    VideoTelemetryService.instance.updateRuntimeHints(
      videoId,
      isAudible: true,
      hasStableFocus: true,
    );

    final snapshot =
        VideoTelemetryService.instance.activeSessionSnapshot(videoId);

    expect(snapshot, isNotNull);
    expect(snapshot!.isAudible, isTrue);
    expect(snapshot.hasStableFocus, isTrue);

    await VideoTelemetryService.instance.endSession(videoId);
  });

  test('video telemetry ignores startup buffering before first frame', () {
    final metrics = VideoSessionMetrics(
      videoId: 'telemetry_startup_buffering',
      videoUrl: 'https://cdn.example.com/startup.m3u8',
    );

    metrics.onBufferingStart();
    metrics.onBufferingEnd();

    expect(metrics.rebufferCount, 0);
    expect(metrics.totalRebufferMs, 0);

    metrics.markFirstFrame();
    metrics.onBufferingStart();
    metrics.onBufferingEnd();

    expect(metrics.rebufferCount, 1);
  });
}
