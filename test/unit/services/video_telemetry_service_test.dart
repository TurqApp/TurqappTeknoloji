import 'package:flutter_test/flutter_test.dart';
import 'package:turqappv2/Core/Services/video_telemetry_service.dart';

void main() {
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
}
