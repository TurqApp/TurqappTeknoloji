import 'package:flutter_test/flutter_test.dart';
import 'package:turqappv2/Core/Services/device_log_reporter.dart';

void main() {
  test('builds admin-first device log report with aggregated issues', () {
    const rawLog = '''
03-25 21:10:41.533  2099  2099 D PlaybackHealthMonitor#37: firstFrameRendered ttffMs=456
03-25 21:10:41.564  2099  2099 D PlaybackHealthMonitor#37: playerReady
03-25 21:10:41.565  2099  2099 D PlaybackHealthMonitor#37: playbackStarted
03-25 21:10:41.657  2099  2108 W JavaBinder: BinderProxy is being destroyed but the application did not call unlinkToDeath to unlink all of its death recipients beforehand.
03-25 21:10:41.672  2099  2155 E FrameEvents: updateAcquireFence: Did not find frame.
03-25 21:10:41.706  2099  2155 E FrameEvents: updateAcquireFence: Did not find frame.
03-25 21:10:41.562  2099  7254 W PesReader: Unexpected start code prefix: 3211315
03-25 21:10:41.673  6563  6563 E audit   : type=1400 audit(1774462241.669:27336): avc:  denied  { getattr }
''';

    final report = DeviceLogReporter.buildReport(
      rawLog,
      deviceId: 'device-1',
      platform: 'android',
    );
    final json = report.toJson();
    final summary = json['summary'] as Map<String, dynamic>;
    final metrics = json['metrics'] as Map<String, dynamic>;
    final issues = json['issues'] as List<dynamic>;

    expect(summary['adminReportRequired'], isTrue);
    expect(summary['triageState'], 'pending_admin_report');
    expect(summary['issueCount'], 4);
    expect(summary['errorCount'], 1);
    expect(summary['warningCount'], 3);
    expect(summary['hasBlocking'], isFalse);
    expect(metrics['firstFrameTtffMs'], 456);
    expect(metrics['frameAcquireFenceMissCount'], 2);
    expect(
      issues.any((issue) =>
          (issue as Map<String, dynamic>)['code'] ==
          'frame_events_missing_acquire_fence'),
      isTrue,
    );
    final frameIssue = issues.cast<Map<String, dynamic>>().firstWhere(
        (issue) => issue['code'] == 'frame_events_missing_acquire_fence');
    final context = frameIssue['context'] as Map<String, dynamic>;
    expect(context['rootCauseCategory'], 'startup_render_transition');
  });

  test('marks fatal signals as blocking', () {
    const rawLog = '''
03-25 21:10:41.000  2099  2099 E AndroidRuntime: FATAL EXCEPTION: main
''';

    final report = DeviceLogReporter.buildReport(
      rawLog,
      deviceId: 'device-2',
      platform: 'android',
    );
    final summary = report.toJson()['summary'] as Map<String, dynamic>;

    expect(summary['hasBlocking'], isTrue);
    expect(summary['blockingCount'], 1);
  });

  test('ignores unrelated process deaths from other packages', () {
    const rawLog = '''
04-19 18:10:41.000  2099  2099 W ActivityManager: Process com.samsung.android.app.galaxyfinder:appservice (pid 12345) has died
''';

    final report = DeviceLogReporter.buildReport(
      rawLog,
      deviceId: 'device-2b',
      platform: 'android',
      packageName: 'com.turqapp.app',
      processId: '9988',
    );
    final summary = report.toJson()['summary'] as Map<String, dynamic>;

    expect(summary['hasBlocking'], isFalse);
    expect(summary['blockingCount'], 0);
  });

  test('marks matching package process deaths as blocking', () {
    const rawLog = '''
04-19 18:10:41.000  2099  2099 W ActivityManager: Process com.turqapp.app (pid 9988) has died
''';

    final report = DeviceLogReporter.buildReport(
      rawLog,
      deviceId: 'device-2c',
      platform: 'android',
      packageName: 'com.turqapp.app',
      processId: '9988',
    );
    final summary = report.toJson()['summary'] as Map<String, dynamic>;

    expect(summary['hasBlocking'], isTrue);
    expect(summary['blockingCount'], 1);
  });

  test('flags repeated stagnant playback positions without startup signals',
      () {
    final rawLog = <String>[
      for (var i = 0; i < 12; i += 1) ...<String>[
        '03-25 21:18:30.124  2099  2099 D PlaybackHealthMonitor#11: position=0',
        '03-25 21:18:30.235  2099  2099 D PlaybackHealthMonitor#12: position=41730',
      ],
    ].join('\n');

    final report = DeviceLogReporter.buildReport(
      rawLog,
      deviceId: 'device-3',
      platform: 'android',
    );
    final json = report.toJson();
    final summary = json['summary'] as Map<String, dynamic>;
    final issues =
        (json['issues'] as List<dynamic>).cast<Map<String, dynamic>>();
    final stuckIssues = issues
        .where((issue) => issue['code'] == 'playback_position_stuck')
        .toList(growable: false);

    expect(summary['hasIssues'], isTrue);
    expect(summary['issueCount'], 2);
    expect(summary['warningCount'], 2);
    expect(stuckIssues, hasLength(2));
    expect(stuckIssues.every((issue) => issue['count'] == 12), isTrue);
    expect(
      stuckIssues.any(
        (issue) => (issue['message'] as String).contains('position=0'),
      ),
      isTrue,
    );
    expect(
      stuckIssues.any(
        (issue) => (issue['message'] as String).contains('position=41730'),
      ),
      isTrue,
    );
  });

  test('ignores stagnant playback positions after playback ended', () {
    final rawLog = <String>[
      '03-25 22:15:36.349 22496 22496 D ExoPlayerPlaybackProbe#191: state=ENDED position=75137',
      for (var i = 0; i < 12; i += 1)
        '03-25 22:15:36.${400 + i} 22496 22496 D PlaybackHealthMonitor#191: position=75137',
    ].join('\n');

    final report = DeviceLogReporter.buildReport(
      rawLog,
      deviceId: 'device-4',
      platform: 'android',
    );
    final json = report.toJson();
    final summary = json['summary'] as Map<String, dynamic>;
    final issues =
        (json['issues'] as List<dynamic>).cast<Map<String, dynamic>>();

    expect(summary['hasIssues'], isFalse);
    expect(summary['issueCount'], 0);
    expect(
      issues.any((issue) => issue['code'] == 'playback_position_stuck'),
      isFalse,
    );
  });

  test('correlates frame event bursts with renderer recovery signals', () {
    const rawLog = '''
03-25 22:15:34.100 22496 22496 W ExoPlayerView#191: rendererStall kind=clock_stalled position=74.1 frameSilenceMs=2200 firstFrameAgeMs=8000 advancedMs=0 recoveryAttempt=1
03-25 22:15:34.120 22496 22496 W ExoPlayerView#191: surfaceRebind position=74.1 recoveryAttempt=1
03-25 22:15:34.125 22496 22625 E FrameEvents: updateAcquireFence: Did not find frame.
03-25 22:15:34.157 22496 22625 E FrameEvents: updateAcquireFence: Did not find frame.
''';

    final report = DeviceLogReporter.buildReport(
      rawLog,
      deviceId: 'device-5',
      platform: 'android',
    );
    final issue = (report.toJson()['issues'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .firstWhere(
          (item) => item['code'] == 'frame_events_missing_acquire_fence',
        );
    final context = issue['context'] as Map<String, dynamic>;

    expect(context['rootCauseCategory'], 'renderer_recovery');
    expect(
      (issue['message'] as String).contains('renderer recovery'),
      isTrue,
    );
  });

  test('correlates pes warnings with the nearest served playback segment', () {
    const rawLog = '''
03-25 22:16:09.400 22496 22496 D flutter : [HlsSegmentServe] doc=doc-1 segment=720p/segment_17.ts cacheHit=false bytes=524288 path=/Posts/doc-1/hls/720p/segment_17.ts
03-25 22:16:09.912 22496 22501 W PesReader: Unexpected start code prefix: 3211513
''';

    final report = DeviceLogReporter.buildReport(
      rawLog,
      deviceId: 'device-6',
      platform: 'android',
    );
    final issue = (report.toJson()['issues'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .firstWhere(
          (item) => item['code'] == 'unexpected_pes_start_code',
        );
    final context = issue['context'] as Map<String, dynamic>;
    final servedSegment = context['servedSegment'] as Map<String, dynamic>;

    expect(servedSegment['docId'], 'doc-1');
    expect(servedSegment['segmentKey'], '720p/segment_17.ts');
    expect(servedSegment['cacheHit'], isFalse);
    expect(servedSegment['bytes'], 524288);
    expect(
      servedSegment['path'],
      '/Posts/doc-1/hls/720p/segment_17.ts',
    );
    expect(context['deltaMs'], 512);
  });

  test('captures app check google api proxy fallback and buffer churn warnings',
      () {
    const rawLog = '''
04-19 17:00:00.100 29236 29236 W LocalRequestInterceptor: Error getting App Check token; using placeholder token instead. Error: com.google.firebase.FirebaseException: No AppCheckProvider installed.
04-19 17:00:00.120 29236 29236 W GoogleApiManager: Not showing notification since connectionResult is not user-facing: ConnectionResult{statusCode=DEVELOPER_ERROR, resolution=null, message=null, clientMethodKey=null}
04-19 17:00:00.150 29236 29236 I flutter: [HLSAdapter] Proxy fallback kept original url=https://cdn.turqapp.com/Posts/doc-1/hls/master.m3u8 proxyRegistered=false proxyStarted=false cacheReady=false
04-19 17:00:00.200 29236 29236 W BufferQueueConsumer: [SurfaceView[com.turqapp.app/com.turqapp.app.MainActivity]#1] freeAllBuffers: 11 buffers were freed while being dequeued!
''';

    final report = DeviceLogReporter.buildReport(
      rawLog,
      deviceId: 'device-7',
      platform: 'android',
      packageName: 'com.turqapp.app',
    );
    final json = report.toJson();
    final summary = json['summary'] as Map<String, dynamic>;
    final metrics = json['metrics'] as Map<String, dynamic>;
    final issues =
        (json['issues'] as List<dynamic>).cast<Map<String, dynamic>>();

    expect(summary['issueCount'], 4);
    expect(summary['warningCount'], 4);
    expect(metrics['appCheckPlaceholderCount'], 1);
    expect(metrics['googleApiDeveloperErrorCount'], 1);
    expect(metrics['hlsProxyFallbackCount'], 1);
    expect(metrics['surfaceFreeAllBuffersCount'], 1);

    final proxyFallback = issues.firstWhere(
      (issue) => issue['code'] == 'hls_proxy_fallback_original_url',
    );
    final context = proxyFallback['context'] as Map<String, dynamic>;
    expect(
      context['url'],
      'https://cdn.turqapp.com/Posts/doc-1/hls/master.m3u8',
    );
    expect(context['proxyRegistered'], isFalse);
    expect(context['proxyStarted'], isFalse);
    expect(context['cacheReady'], isFalse);
  });
}
