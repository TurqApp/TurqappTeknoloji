import 'package:flutter_test/flutter_test.dart';
import 'package:turqappv2/Core/Services/qa_lab_recorder.dart';

void main() {
  test('qa recorder flags feed first-frame timeout', () {
    final recorder = QALabRecorder();
    final now = DateTime.now();

    recorder.checkpoints.add(
      QALabCheckpoint(
        id: 'cp1',
        label: 'feed_visible',
        surface: 'feed',
        route: '/NavBar',
        timestamp: now,
        probe: <String, dynamic>{
          'feed': <String, dynamic>{
            'registered': true,
            'count': 1,
            'centeredIndex': 0,
            'playbackSuspended': false,
            'pauseAll': false,
            'canClaimPlaybackNow': true,
          },
          'auth': <String, dynamic>{
            'currentUid': 'user-1',
            'isFirebaseSignedIn': true,
            'currentUserLoaded': true,
          },
        },
      ),
    );
    recorder.issues.add(
      QALabIssue(
        id: 'issue1',
        source: QALabIssueSource.video,
        severity: QALabIssueSeverity.info,
        code: 'video_session_started',
        message: 'Video session started',
        timestamp: now.subtract(const Duration(seconds: 10)),
        route: '/NavBar',
        surface: 'feed',
        metadata: const <String, dynamic>{
          'videoId': 'video-1',
        },
      ),
    );

    final findings = recorder.buildPinpointFindings();

    expect(
      findings.any((item) => item.code == 'feed_first_frame_timeout'),
      isTrue,
    );
  });

  test('qa recorder flags authenticated short blank surface', () {
    final recorder = QALabRecorder();
    final now = DateTime.now();

    recorder.checkpoints.add(
      QALabCheckpoint(
        id: 'cp2',
        label: 'short_loaded',
        surface: 'short',
        route: '/ShortView',
        timestamp: now,
        probe: <String, dynamic>{
          'short': <String, dynamic>{
            'registered': true,
            'count': 0,
            'activeIndex': -1,
          },
          'auth': <String, dynamic>{
            'currentUid': 'user-1',
            'isFirebaseSignedIn': true,
            'currentUserLoaded': true,
          },
        },
      ),
    );

    final diagnostics = recorder.buildFocusSurfaceDiagnostics();
    final shortDiagnostic = diagnostics.firstWhere(
      (item) => item.surface == 'short',
    );

    expect(
      shortDiagnostic.findings
          .any((item) => item.code == 'short_blank_surface'),
      isTrue,
    );
  });

  test('qa recorder surfaces feed noise bursts and jank counts', () {
    final recorder = QALabRecorder();
    final now = DateTime.now();

    recorder.checkpoints.add(
      QALabCheckpoint(
        id: 'cp3',
        label: 'feed_runtime',
        surface: 'feed',
        route: '/NavBar',
        timestamp: now,
        probe: <String, dynamic>{
          'feed': <String, dynamic>{
            'registered': true,
            'count': 3,
            'centeredIndex': 1,
            'playbackSuspended': false,
            'pauseAll': false,
            'canClaimPlaybackNow': true,
          },
          'auth': <String, dynamic>{
            'currentUid': 'user-1',
            'isFirebaseSignedIn': true,
            'currentUserLoaded': true,
          },
        },
      ),
    );
    for (var i = 0; i < 3; i += 1) {
      recorder.issues.add(
        QALabIssue(
          id: 'noise_$i',
          source: QALabIssueSource.platform,
          severity: QALabIssueSeverity.info,
          code: 'platform_suppressed',
          message: 'suppressed noise',
          timestamp: now.subtract(Duration(seconds: i + 1)),
          route: '/NavBar',
          surface: 'feed',
        ),
      );
    }
    recorder.issues.add(
      QALabIssue(
        id: 'jank_1',
        source: QALabIssueSource.performance,
        severity: QALabIssueSeverity.error,
        code: 'frame_jank_error',
        message: 'Frame pipeline slowed down on feed.',
        timestamp: now.subtract(const Duration(seconds: 2)),
        route: '/NavBar',
        surface: 'feed',
        metadata: const <String, dynamic>{
          'maxTotalMs': 88,
        },
      ),
    );

    final diagnostics = recorder.buildFocusSurfaceDiagnostics();
    final feedDiagnostic = diagnostics.firstWhere(
      (item) => item.surface == 'feed',
    );

    expect(feedDiagnostic.runtime['jankEventCount'], 1);
    expect(feedDiagnostic.runtime['suppressedNoiseCount'], 3);
    expect(
      feedDiagnostic.findings.any((item) => item.code == 'feed_noise_burst'),
      isTrue,
    );
  });

  test('qa recorder flags feed autoplay missing after grace window', () {
    final recorder = QALabRecorder();
    final now = DateTime.now();
    final probe = <String, dynamic>{
      'feed': <String, dynamic>{
        'registered': true,
        'count': 2,
        'centeredIndex': 0,
        'centeredDocId': 'post-1',
        'playbackSuspended': false,
        'pauseAll': false,
        'canClaimPlaybackNow': true,
      },
      'auth': <String, dynamic>{
        'currentUid': 'user-1',
        'isFirebaseSignedIn': true,
        'currentUserLoaded': true,
      },
      'videoPlayback': <String, dynamic>{
        'registered': true,
        'currentPlayingDocID': '',
        'registeredHandleCount': 1,
        'savedStateCount': 0,
      },
    };

    recorder.checkpoints.addAll(<QALabCheckpoint>[
      QALabCheckpoint(
        id: 'cp4',
        label: 'feed_visible',
        surface: 'feed',
        route: '/NavBar',
        timestamp: now.subtract(const Duration(seconds: 5)),
        probe: probe,
      ),
      QALabCheckpoint(
        id: 'cp5',
        label: 'feed_watchdog',
        surface: 'feed',
        route: '/NavBar',
        timestamp: now,
        probe: probe,
      ),
    ]);

    final findings = recorder.buildPinpointFindings();

    expect(
      findings.any((item) => item.code == 'feed_autoplay_missing'),
      isTrue,
    );
  });

  test('qa recorder builds surface alert summaries with blockers first', () {
    final recorder = QALabRecorder();
    final now = DateTime.now();

    recorder.checkpoints.addAll(<QALabCheckpoint>[
      QALabCheckpoint(
        id: 'cp6',
        label: 'feed_loaded',
        surface: 'feed',
        route: '/NavBar',
        timestamp: now,
        probe: <String, dynamic>{
          'feed': <String, dynamic>{
            'registered': true,
            'count': 0,
          },
          'auth': <String, dynamic>{
            'currentUid': 'user-1',
            'isFirebaseSignedIn': true,
            'currentUserLoaded': true,
          },
        },
      ),
      QALabCheckpoint(
        id: 'cp7',
        label: 'short_runtime',
        surface: 'short',
        route: '/ShortView',
        timestamp: now,
        probe: <String, dynamic>{
          'short': <String, dynamic>{
            'registered': true,
            'count': 2,
            'activeIndex': 1,
            'activeDocId': 'short-2',
          },
          'auth': <String, dynamic>{
            'currentUid': 'user-1',
            'isFirebaseSignedIn': true,
            'currentUserLoaded': true,
          },
          'videoPlayback': <String, dynamic>{
            'registered': true,
            'currentPlayingDocID': '',
            'registeredHandleCount': 0,
            'savedStateCount': 0,
          },
        },
      ),
    ]);

    final summaries = recorder.buildSurfaceAlertSummaries();

    expect(summaries, isNotEmpty);
    expect(summaries.first.surface, 'feed');
    expect(summaries.first.blockingCount, greaterThan(0));
    expect(summaries.first.headlineCode, 'feed_blank_surface');
    expect(summaries.first.primaryRootCauseCategory, 'data_absent');
    expect(summaries.first.primaryRootCauseDetail, contains('empty'));
  });

  test('qa recorder maps autoplay findings to autoplay root cause', () {
    final recorder = QALabRecorder();
    final now = DateTime.now();
    final probe = <String, dynamic>{
      'feed': <String, dynamic>{
        'registered': true,
        'count': 2,
        'centeredIndex': 0,
        'centeredDocId': 'post-1',
        'playbackSuspended': false,
        'pauseAll': false,
        'canClaimPlaybackNow': true,
      },
      'auth': <String, dynamic>{
        'currentUid': 'user-1',
        'isFirebaseSignedIn': true,
        'currentUserLoaded': true,
      },
      'videoPlayback': <String, dynamic>{
        'registered': true,
        'currentPlayingDocID': '',
        'registeredHandleCount': 1,
        'savedStateCount': 0,
      },
    };

    recorder.checkpoints.addAll(<QALabCheckpoint>[
      QALabCheckpoint(
        id: 'cp8',
        label: 'feed_visible',
        surface: 'feed',
        route: '/NavBar',
        timestamp: now.subtract(const Duration(seconds: 5)),
        probe: probe,
      ),
      QALabCheckpoint(
        id: 'cp9',
        label: 'feed_watchdog',
        surface: 'feed',
        route: '/NavBar',
        timestamp: now,
        probe: probe,
      ),
    ]);

    final summaries = recorder.buildSurfaceAlertSummaries();
    final feedSummary = summaries.firstWhere((item) => item.surface == 'feed');

    expect(feedSummary.headlineCode, 'feed_autoplay_missing');
    expect(feedSummary.primaryRootCauseCategory, 'autoplay_dispatch');
    expect(feedSummary.primaryRootCauseDetail, contains('autoplay'));
  });

  test('qa recorder flags inconsistent feed audio state across sessions', () {
    final recorder = QALabRecorder();
    final now = DateTime.now();

    recorder.checkpoints.add(
      QALabCheckpoint(
        id: 'cp10',
        label: 'feed_runtime',
        surface: 'feed',
        route: '/NavBar',
        timestamp: now,
        probe: <String, dynamic>{
          'feed': <String, dynamic>{
            'registered': true,
            'count': 3,
            'centeredIndex': 1,
            'centeredDocId': 'post-2',
            'playbackSuspended': false,
            'pauseAll': false,
            'canClaimPlaybackNow': true,
          },
          'auth': <String, dynamic>{
            'currentUid': 'user-1',
            'isFirebaseSignedIn': true,
            'currentUserLoaded': true,
          },
        },
      ),
    );
    recorder.issues.addAll(<QALabIssue>[
      QALabIssue(
        id: 'audio_1',
        source: QALabIssueSource.video,
        severity: QALabIssueSeverity.info,
        code: 'video_session_ended',
        message: 'Video session ended',
        timestamp: now.subtract(const Duration(seconds: 4)),
        route: '/NavBar',
        surface: 'feed',
        metadata: const <String, dynamic>{
          'videoId': 'post-1',
          'isAudible': true,
          'hasStableFocus': true,
        },
      ),
      QALabIssue(
        id: 'audio_2',
        source: QALabIssueSource.video,
        severity: QALabIssueSeverity.info,
        code: 'video_session_ended',
        message: 'Video session ended',
        timestamp: now.subtract(const Duration(seconds: 2)),
        route: '/NavBar',
        surface: 'feed',
        metadata: const <String, dynamic>{
          'videoId': 'post-2',
          'isAudible': false,
          'hasStableFocus': false,
        },
      ),
    ]);

    final findings = recorder.buildPinpointFindings();
    final summaries = recorder.buildSurfaceAlertSummaries();
    final feedSummary = summaries.firstWhere((item) => item.surface == 'feed');

    expect(
      findings.any((item) => item.code == 'feed_audio_state_inconsistent'),
      isTrue,
    );
    expect(feedSummary.primaryRootCauseCategory, 'audio_state_drift');
  });

  test('qa recorder flags native iOS first-frame timeout in feed summary', () {
    final recorder = QALabRecorder();
    final now = DateTime.now();

    recorder.checkpoints.add(
      QALabCheckpoint(
        id: 'cp11',
        label: 'feed_runtime',
        surface: 'feed',
        route: '/NavBar',
        timestamp: now,
        probe: <String, dynamic>{
          'feed': <String, dynamic>{
            'registered': true,
            'count': 2,
            'centeredIndex': 0,
            'centeredDocId': 'post-1',
            'playbackSuspended': false,
            'pauseAll': false,
            'canClaimPlaybackNow': true,
          },
          'auth': <String, dynamic>{
            'currentUid': 'user-1',
            'isFirebaseSignedIn': true,
            'currentUserLoaded': true,
          },
        },
      ),
    );
    recorder.lastNativePlaybackSnapshot
      ..clear()
      ..addAll(<String, dynamic>{
        'platform': 'iOS',
        'status': 'FIRST_FRAME_TIMEOUT',
        'errors': const <String>['FIRST_FRAME_TIMEOUT', 'PLAYBACK_NOT_STARTED'],
        'active': true,
        'firstFrameRendered': false,
        'isPlaybackExpected': true,
        'isPlaying': false,
        'isBuffering': false,
        'stallCount': 0,
        'layerAttachCount': 2,
        'lastKnownPlaybackTime': 0.0,
        'sampledAt': now.toUtc().toIso8601String(),
        'trigger': 'test',
        'supported': true,
      });

    final findings = recorder.buildPinpointFindings();
    final summaries = recorder.buildSurfaceAlertSummaries();
    final feedSummary = summaries.firstWhere((item) => item.surface == 'feed');

    expect(
      findings.any((item) => item.code == 'feed_native_first_frame_timeout'),
      isTrue,
    );
    expect(feedSummary.primaryRootCauseCategory, 'first_frame_latency');
  });

  test('qa recorder export includes native playback diagnostics', () {
    final recorder = QALabRecorder();
    final now = DateTime.now();

    recorder.lastNativePlaybackSnapshot
      ..clear()
      ..addAll(<String, dynamic>{
        'platform': 'iOS',
        'status': 'OK',
        'errors': const <String>[],
        'active': true,
        'firstFrameRendered': true,
        'isPlaybackExpected': true,
        'isPlaying': true,
        'isBuffering': false,
        'stallCount': 0,
        'sampledAt': now.toUtc().toIso8601String(),
        'trigger': 'test',
        'supported': true,
      });
    recorder.nativePlaybackSamples.add(
      Map<String, dynamic>.from(recorder.lastNativePlaybackSnapshot),
    );

    final export = recorder.buildExportJson();
    final nativePlayback = export['nativePlayback'] as Map<String, dynamic>? ??
        <String, dynamic>{};
    final latest = nativePlayback['latestSnapshot'] as Map<String, dynamic>? ??
        <String, dynamic>{};

    expect(nativePlayback['sampleCount'], 1);
    expect(latest['platform'], 'iOS');
    expect(latest['firstFrameRendered'], isTrue);
  });
}
