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

  test('Android warm pool retains five warmed feed adapters without trimming', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final pool = GlobalVideoAdapterPool();

    final adapters = List.generate(
      5,
      (index) => pool.acquire(
        cacheKey: 'feed:test-doc-$index',
        url: 'https://cdn.turqapp.com/Posts/test-doc-$index/hls/master.m3u8',
      ),
    );

    for (final adapter in adapters) {
      await pool.release(adapter, keepWarm: true);
    }

    final snapshot = pool.debugSnapshot();
    expect(snapshot['maxWarmCount'], 5);
    expect(snapshot['warmCount'], 5);
    await pool.clear();
  });
}
