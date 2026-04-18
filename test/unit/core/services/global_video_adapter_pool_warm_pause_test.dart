import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turqappv2/Core/Services/global_video_adapter_pool.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
  });

  test('Android short acquire marks adapter for warm-pool pause', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final pool = GlobalVideoAdapterPool();

    final adapter = pool.acquire(
      cacheKey: 'short:test-doc',
      url: 'https://cdn.turqapp.com/Posts/test-doc/hls/master.m3u8',
      preferWarmPoolPauseOnAndroid: true,
    );

    expect(adapter.preferWarmPoolPause, isTrue);
    await pool.clear();
  });

  test('default acquire keeps warm-pool pause disabled', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final pool = GlobalVideoAdapterPool();

    final adapter = pool.acquire(
      cacheKey: 'feed:test-doc',
      url: 'https://cdn.turqapp.com/Posts/test-doc/hls/master.m3u8',
    );

    expect(adapter.preferWarmPoolPause, isFalse);
    await pool.clear();
  });
}
