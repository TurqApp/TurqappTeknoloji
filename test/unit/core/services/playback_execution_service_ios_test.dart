import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turqappv2/Core/Services/playback_execution_service.dart';
import 'package:turqappv2/hls_player/hls_video_adapter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
  });

  test('iOS stopAdapter keeps warm short adapters restartable', () async {
    final service = PlaybackExecutionService(
      platformOverride: TargetPlatform.iOS,
    );
    final adapter = HLSVideoAdapter(
      url: 'https://cdn.turqapp.com/Posts/test-doc/hls/master.m3u8',
      autoPlay: false,
      loop: false,
    );

    adapter.updateWarmPoolPausePreference(true);

    await service.stopAdapter(adapter);

    expect(adapter.isStopped, isFalse);
    adapter.dispose();
  });

  test('iOS stopAdapter still fully stops cold adapters', () async {
    final service = PlaybackExecutionService(
      platformOverride: TargetPlatform.iOS,
    );
    final adapter = HLSVideoAdapter(
      url: 'https://cdn.turqapp.com/Posts/test-doc/hls/master.m3u8',
      autoPlay: false,
      loop: false,
    );

    await service.stopAdapter(adapter);

    expect(adapter.isStopped, isTrue);
    adapter.dispose();
  });
}
