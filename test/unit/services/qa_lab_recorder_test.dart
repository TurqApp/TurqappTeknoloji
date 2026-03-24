import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turqappv2/Core/Services/qa_lab_recorder.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  tearDown(Get.reset);

  test('qa recorder flags feed first-frame timeout', () {
    final recorder = QALabRecorder();
    final now = DateTime.now();

    final probe = <String, dynamic>{
      'feed': <String, dynamic>{
        'registered': true,
        'count': 1,
        'centeredIndex': 0,
        'centeredDocId': 'video-1',
        'centeredHasPlayableVideo': true,
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
        'currentPlayingDocID': 'video-1',
        'registeredHandleCount': 1,
        'savedStateCount': 0,
      },
    };
    recorder.checkpoints.addAll(<QALabCheckpoint>[
      QALabCheckpoint(
        id: 'cp1a',
        label: 'feed_visible',
        surface: 'feed',
        route: '/NavBar',
        timestamp: now.subtract(const Duration(seconds: 12)),
        probe: probe,
      ),
      QALabCheckpoint(
        id: 'cp1b',
        label: 'feed_watchdog',
        surface: 'feed',
        route: '/NavBar',
        timestamp: now,
        probe: probe,
      ),
    ]);
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

  test('qa recorder ignores native feed first-frame timeout while gate blocked',
      () {
    final recorder = QALabRecorder();
    final now = DateTime.now();

    recorder.checkpoints.add(
      QALabCheckpoint(
        id: 'cp_gate_blocked',
        label: 'feed_runtime',
        surface: 'feed',
        route: '/NavBar',
        timestamp: now,
        probe: <String, dynamic>{
          'feed': <String, dynamic>{
            'registered': true,
            'count': 1,
            'centeredIndex': 0,
            'centeredDocId': 'video-1',
            'centeredHasPlayableVideo': true,
            'playbackSuspended': false,
            'pauseAll': false,
            'canClaimPlaybackNow': false,
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
        'platform': 'android',
        'status': 'FIRST_FRAME_TIMEOUT|PLAYBACK_NOT_STARTED',
        'errors': const <String>['FIRST_FRAME_TIMEOUT', 'PLAYBACK_NOT_STARTED'],
        'active': true,
        'firstFrameRendered': false,
        'isPlaybackExpected': true,
        'isPlaying': false,
        'isBuffering': false,
        'stallCount': 0,
        'layerAttachCount': 1,
        'lastKnownPlaybackTime': 0.0,
        'sampledAt': now.toUtc().toIso8601String(),
        'trigger': 'test',
        'supported': true,
      });

    final findings = recorder.buildPinpointFindings();

    expect(
      findings.any((item) => item.code == 'feed_native_first_frame_timeout'),
      isFalse,
    );
  });

  test('qa recorder ignores stale feed video timeout for non-active doc', () {
    final recorder = QALabRecorder();
    final now = DateTime.now();

    recorder.checkpoints.add(
      QALabCheckpoint(
        id: 'cp1b',
        label: 'feed_visible',
        surface: 'feed',
        route: '/NavBar',
        timestamp: now,
        probe: <String, dynamic>{
          'feed': <String, dynamic>{
            'registered': true,
            'count': 1,
            'centeredIndex': 0,
            'centeredDocId': 'video-2',
            'centeredHasPlayableVideo': true,
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
            'currentPlayingDocID': 'video-2',
            'registeredHandleCount': 1,
            'savedStateCount': 0,
          },
        },
      ),
    );
    recorder.issues.add(
      QALabIssue(
        id: 'issue1b',
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
      isFalse,
    );
  });

  test('qa recorder ignores feed blank surface after recent host lookup error',
      () {
    final recorder = QALabRecorder();
    final now = DateTime.now();

    recorder.checkpoints.add(
      QALabCheckpoint(
        id: 'feed_blank_cp',
        label: 'feed_runtime',
        surface: 'feed',
        route: '/NavBarView',
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
    );
    recorder.issues.add(
      QALabIssue(
        id: 'feed_host_lookup',
        source: QALabIssueSource.platform,
        severity: QALabIssueSeverity.error,
        code: 'platform_error',
        message:
            "ClientException with SocketException: Failed host lookup: 'firebasestorage.googleapis.com'",
        timestamp: now.subtract(const Duration(seconds: 3)),
        route: '/NavBarView',
        surface: 'feed',
      ),
    );

    final findings = recorder.buildPinpointFindings();

    expect(
      findings.any((item) => item.code == 'feed_blank_surface'),
      isFalse,
    );
  });

  test('qa recorder specializes platform host lookup failures', () {
    final recorder = QALabRecorder();
    final now = DateTime.now();

    recorder.issues.add(
      QALabIssue(
        id: 'feed_host_lookup_specialized',
        source: QALabIssueSource.platform,
        severity: QALabIssueSeverity.error,
        code: 'platform_error',
        message:
            "ClientException with SocketException: Failed host lookup: 'firebasestorage.googleapis.com'",
        timestamp: now,
        route: '/NavBarView',
        surface: 'feed',
      ),
    );

    final findings = recorder.buildPinpointFindings();
    final finding = findings.firstWhere(
      (item) => item.code == 'feed_host_lookup_failed',
    );

    expect(finding.message, contains('hostname resolution'));
    expect(finding.context['host'], 'firebasestorage.googleapis.com');
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

  test('qa recorder emits runtime findings for observed non-focus surfaces',
      () {
    final recorder = QALabRecorder();
    final now = DateTime.now();

    recorder.checkpoints.add(
      QALabCheckpoint(
        id: 'market_cp1',
        label: 'market_runtime',
        surface: 'market',
        route: '/MarketView',
        timestamp: now,
        probe: const <String, dynamic>{},
      ),
    );
    for (var i = 0; i < 3; i += 1) {
      recorder.issues.add(
        QALabIssue(
          id: 'market_noise_$i',
          source: QALabIssueSource.platform,
          severity: QALabIssueSeverity.info,
          code: 'platform_suppressed',
          message: 'suppressed noise',
          timestamp: now.subtract(Duration(seconds: i + 1)),
          route: '/MarketView',
          surface: 'market',
        ),
      );
    }

    final findings = recorder.buildPinpointFindings();

    expect(
      findings.any((item) => item.code == 'market_noise_burst'),
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
        'centeredHasPlayableVideo': true,
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

  test('qa recorder requires persistent feed wrong-target autoplay mismatch',
      () {
    final recorder = QALabRecorder();
    final now = DateTime.now();

    recorder.checkpoints.addAll(<QALabCheckpoint>[
      QALabCheckpoint(
        id: 'cp5a',
        label: 'feed_visible',
        surface: 'feed',
        route: '/NavBar',
        timestamp: now.subtract(const Duration(seconds: 5)),
        probe: <String, dynamic>{
          'feed': <String, dynamic>{
            'registered': true,
            'count': 2,
            'centeredIndex': 0,
            'centeredDocId': 'post-1',
            'centeredHasPlayableVideo': true,
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
            'currentPlayingDocID': 'post-1',
            'registeredHandleCount': 1,
            'savedStateCount': 0,
          },
        },
      ),
      QALabCheckpoint(
        id: 'cp5b',
        label: 'feed_watchdog',
        surface: 'feed',
        route: '/NavBar',
        timestamp: now,
        probe: <String, dynamic>{
          'feed': <String, dynamic>{
            'registered': true,
            'count': 2,
            'centeredIndex': 0,
            'centeredDocId': 'post-1',
            'centeredHasPlayableVideo': true,
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
            'currentPlayingDocID': 'post-2',
            'registeredHandleCount': 1,
            'savedStateCount': 0,
          },
        },
      ),
    ]);

    final findings = recorder.buildPinpointFindings();

    expect(
      findings.any((item) => item.code == 'feed_autoplay_wrong_target'),
      isFalse,
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

  test(
      'qa recorder ignores feed centered index invalid after recent host lookup error',
      () {
    final recorder = QALabRecorder();
    final now = DateTime.now();

    recorder.checkpoints.add(
      QALabCheckpoint(
        id: 'feed_center_invalid_cp',
        label: 'feed_runtime',
        surface: 'feed',
        route: '/NavBarView',
        timestamp: now,
        probe: <String, dynamic>{
          'feed': <String, dynamic>{
            'registered': true,
            'count': 3,
            'centeredIndex': -1,
            'centeredDocId': '',
            'centeredHasPlayableVideo': false,
            'playbackSuspended': false,
            'pauseAll': false,
            'canClaimPlaybackNow': false,
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
        id: 'feed_center_host_lookup',
        source: QALabIssueSource.platform,
        severity: QALabIssueSeverity.error,
        code: 'platform_error',
        message:
            "ClientException with SocketException: Failed host lookup: 'cdn.turqapp.com'",
        timestamp: now.subtract(const Duration(seconds: 4)),
        route: '/NavBarView',
        surface: 'feed',
      ),
    );

    final findings = recorder.buildPinpointFindings();

    expect(
      findings.any((item) => item.code == 'feed_centered_index_invalid'),
      isFalse,
    );
  });

  test('qa recorder waits before flagging feed centered index invalid', () {
    final recorder = QALabRecorder();
    final now = DateTime.now();

    recorder.checkpoints.add(
      QALabCheckpoint(
        id: 'feed_center_invalid_early',
        label: 'feed_runtime',
        surface: 'feed',
        route: '/NavBarView',
        timestamp: now,
        probe: <String, dynamic>{
          'feed': <String, dynamic>{
            'registered': true,
            'count': 3,
            'centeredIndex': -1,
            'centeredDocId': '',
            'centeredHasPlayableVideo': false,
            'playbackSuspended': false,
            'pauseAll': false,
            'canClaimPlaybackNow': false,
          },
          'auth': <String, dynamic>{
            'currentUid': 'user-1',
            'isFirebaseSignedIn': true,
            'currentUserLoaded': true,
          },
        },
      ),
    );

    final findings = recorder.buildPinpointFindings();

    expect(
      findings.any((item) => item.code == 'feed_centered_index_invalid'),
      isFalse,
    );
  });

  test('qa recorder maps backend unavailable findings to summary root cause', () {
    final recorder = QALabRecorder();
    final now = DateTime.now();

    recorder.checkpoints.add(
      QALabCheckpoint(
        id: 'feed_backend_cp',
        label: 'feed_runtime',
        surface: 'feed',
        route: '/NavBarView',
        timestamp: now,
        probe: <String, dynamic>{
          'feed': <String, dynamic>{
            'registered': true,
            'count': 2,
            'centeredIndex': 0,
            'centeredDocId': 'post-1',
            'centeredHasPlayableVideo': true,
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
        id: 'feed_backend_unavailable',
        source: QALabIssueSource.platform,
        severity: QALabIssueSeverity.error,
        code: 'platform_error',
        message:
            '[cloud_firestore/unavailable] The service is currently unavailable. This is a most likely a transient condition and may be corrected by retrying with a backoff.',
        timestamp: now.subtract(const Duration(seconds: 1)),
        route: '/NavBarView',
        surface: 'feed',
      ),
    );

    final findings = recorder.buildPinpointFindings();
    final summaries = recorder.buildSurfaceAlertSummaries();
    final feedSummary = summaries.firstWhere((item) => item.surface == 'feed');

    expect(
      findings.any((item) => item.code == 'feed_backend_unavailable'),
      isTrue,
    );
    expect(feedSummary.headlineCode, 'feed_backend_unavailable');
    expect(feedSummary.primaryRootCauseCategory, 'backend_unavailable');
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
        'centeredHasPlayableVideo': true,
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
            'centeredHasPlayableVideo': true,
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

    recorder.timelineEvents.add(
      QALabTimelineEvent(
        id: 'timeline_1',
        category: 'feed_fetch',
        code: 'completed',
        route: '/NavBar',
        surface: 'feed',
        timestamp: now,
      ),
    );
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
    expect((export['timeline'] as List<dynamic>).length, 1);
  });

  test('qa recorder flags duplicate feed fetch triggers', () {
    final recorder = QALabRecorder();
    final now = DateTime.now();
    final probe = <String, dynamic>{
      'feed': <String, dynamic>{
        'registered': true,
        'count': 4,
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
        'currentPlayingDocID': 'post-1',
        'registeredHandleCount': 1,
        'savedStateCount': 0,
      },
    };

    recorder.checkpoints.add(
      QALabCheckpoint(
        id: 'cp12',
        label: 'feed_runtime',
        surface: 'feed',
        route: '/NavBar',
        timestamp: now,
        probe: probe,
      ),
    );
    recorder.timelineEvents.addAll(<QALabTimelineEvent>[
      QALabTimelineEvent(
        id: 'tf1',
        category: 'feed_fetch',
        code: 'requested',
        route: '/NavBar',
        surface: 'feed',
        timestamp: now.subtract(const Duration(milliseconds: 900)),
        metadata: const <String, dynamic>{'trigger': 'scroll_near_end'},
      ),
      QALabTimelineEvent(
        id: 'tf2',
        category: 'feed_fetch',
        code: 'started',
        route: '/NavBar',
        surface: 'feed',
        timestamp: now.subtract(const Duration(milliseconds: 600)),
        metadata: const <String, dynamic>{'trigger': 'scroll_near_end'},
      ),
      QALabTimelineEvent(
        id: 'tf3',
        category: 'feed_fetch',
        code: 'requested',
        route: '/NavBar',
        surface: 'feed',
        timestamp: now.subtract(const Duration(milliseconds: 300)),
        metadata: const <String, dynamic>{'trigger': 'scroll_near_end'},
      ),
    ]);

    final findings = recorder.buildPinpointFindings();
    final summaries = recorder.buildSurfaceAlertSummaries();
    final feedSummary = summaries.firstWhere((item) => item.surface == 'feed');

    expect(
      findings.any((item) => item.code == 'feed_duplicate_fetch_trigger'),
      isTrue,
    );
    expect(feedSummary.primaryRootCauseCategory, 'feed_trigger_duplication');
  });

  test('qa recorder flags duplicate playback dispatch bursts', () {
    final recorder = QALabRecorder();
    final now = DateTime.now();
    final probe = <String, dynamic>{
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
      'videoPlayback': <String, dynamic>{
        'registered': true,
        'currentPlayingDocID': 'post-2',
        'registeredHandleCount': 1,
        'savedStateCount': 0,
      },
    };

    recorder.checkpoints.add(
      QALabCheckpoint(
        id: 'cp13',
        label: 'feed_runtime',
        surface: 'feed',
        route: '/NavBar',
        timestamp: now,
        probe: probe,
      ),
    );
    recorder.timelineEvents.addAll(<QALabTimelineEvent>[
      QALabTimelineEvent(
        id: 'ts1',
        category: 'scroll',
        code: 'settled',
        route: '/NavBar',
        surface: 'feed',
        timestamp: now.subtract(const Duration(milliseconds: 300)),
        metadata: const <String, dynamic>{'docId': 'post-2'},
      ),
      QALabTimelineEvent(
        id: 'tp1',
        category: 'playback_dispatch',
        code: 'feed_play_only_this',
        route: '/NavBar',
        surface: 'feed',
        timestamp: now.subtract(const Duration(milliseconds: 220)),
        metadata: const <String, dynamic>{'docId': 'post-2'},
      ),
      QALabTimelineEvent(
        id: 'tp2',
        category: 'playback_dispatch',
        code: 'feed_card_adapter_play',
        route: '/NavBar',
        surface: 'feed',
        timestamp: now.subtract(const Duration(milliseconds: 170)),
        metadata: const <String, dynamic>{'docId': 'post-2'},
      ),
      QALabTimelineEvent(
        id: 'tp3',
        category: 'playback_dispatch',
        code: 'feed_card_video_state_request',
        route: '/NavBar',
        surface: 'feed',
        timestamp: now.subtract(const Duration(milliseconds: 120)),
        metadata: const <String, dynamic>{'docId': 'post-2'},
      ),
    ]);

    final findings = recorder.buildPinpointFindings();
    expect(
      findings.any((item) => item.code == 'feed_duplicate_playback_dispatch'),
      isTrue,
    );
  });

  test('qa recorder flags slow ad loads on feed', () {
    final recorder = QALabRecorder();
    final now = DateTime.now();

    recorder.checkpoints.add(
      QALabCheckpoint(
        id: 'cp14',
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
          'videoPlayback': <String, dynamic>{
            'registered': true,
            'currentPlayingDocID': 'post-1',
            'registeredHandleCount': 1,
            'savedStateCount': 0,
          },
        },
      ),
    );
    recorder.timelineEvents.addAll(<QALabTimelineEvent>[
      QALabTimelineEvent(
        id: 'ad1',
        category: 'ad',
        code: 'requested',
        route: '/NavBar',
        surface: 'feed',
        timestamp: now.subtract(const Duration(seconds: 3)),
        metadata: const <String, dynamic>{'placement': 'medium_rectangle'},
      ),
      QALabTimelineEvent(
        id: 'ad2',
        category: 'ad',
        code: 'loaded',
        route: '/NavBar',
        surface: 'feed',
        timestamp: now,
        metadata: const <String, dynamic>{
          'placement': 'medium_rectangle',
          'latencyMs': 3000,
        },
      ),
    ]);

    final findings = recorder.buildPinpointFindings();
    expect(findings.any((item) => item.code == 'feed_ad_load_slow'), isTrue);
  });

  test('qa recorder includes skip context for feed scroll dispatch timeout',
      () {
    final recorder = QALabRecorder();
    final now = DateTime.now();

    recorder.checkpoints.add(
      QALabCheckpoint(
        id: 'cp15',
        label: 'feed_runtime',
        surface: 'feed',
        route: '/NavBar',
        timestamp: now,
        probe: <String, dynamic>{
          'feed': <String, dynamic>{
            'registered': true,
            'count': 1,
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
    recorder.timelineEvents.addAll(<QALabTimelineEvent>[
      QALabTimelineEvent(
        id: 'ts2',
        category: 'scroll',
        code: 'settled',
        route: '/NavBar',
        surface: 'feed',
        timestamp: now.subtract(const Duration(seconds: 70)),
        metadata: const <String, dynamic>{
          'docId': 'post-1',
          'scrollToken': 'feed-scroll-1',
        },
      ),
      QALabTimelineEvent(
        id: 'tp4',
        category: 'playback_dispatch',
        code: 'feed_card_resume_skipped',
        route: '/NavBar',
        surface: 'feed',
        timestamp: now.subtract(const Duration(seconds: 69)),
        metadata: const <String, dynamic>{
          'docId': 'post-1',
          'dispatchIssued': false,
          'dispatchSource': 'nav_selection_changed',
          'callerSignature': 'nav_selection_changed',
          'skipReason': 'surface_playback_blocked',
          'scrollToken': 'feed-scroll-1',
        },
      ),
    ]);

    final findings = recorder.buildPinpointFindings();
    final finding = findings.firstWhere(
      (item) => item.code == 'feed_scroll_dispatch_timeout',
    );

    expect(finding.context['scrollToken'], 'feed-scroll-1');
    expect(finding.context['lastSkipReason'], 'surface_playback_blocked');
    expect(finding.context['lastSkipSource'], 'nav_selection_changed');
    expect(finding.context['lastCallerSignature'], 'nav_selection_changed');
  });

  test('qa recorder ignores deferred init requests for duplicate dispatches',
      () {
    final recorder = QALabRecorder();
    final now = DateTime.now();

    recorder.checkpoints.add(
      QALabCheckpoint(
        id: 'cp16',
        label: 'feed_runtime',
        surface: 'feed',
        route: '/NavBar',
        timestamp: now,
        probe: <String, dynamic>{
          'feed': <String, dynamic>{
            'registered': true,
            'count': 1,
            'centeredIndex': 0,
            'centeredDocId': 'post-3',
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
    recorder.timelineEvents.addAll(<QALabTimelineEvent>[
      QALabTimelineEvent(
        id: 'ts3',
        category: 'scroll',
        code: 'settled',
        route: '/NavBar',
        surface: 'feed',
        timestamp: now.subtract(const Duration(milliseconds: 500)),
        metadata: const <String, dynamic>{'docId': 'post-3'},
      ),
      QALabTimelineEvent(
        id: 'tp5',
        category: 'playback_dispatch',
        code: 'feed_play_only_this',
        route: '/NavBar',
        surface: 'feed',
        timestamp: now.subtract(const Duration(milliseconds: 300)),
        metadata: const <String, dynamic>{
          'docId': 'post-3',
          'dispatchIssued': true,
        },
      ),
      QALabTimelineEvent(
        id: 'tp6',
        category: 'playback_dispatch',
        code: 'feed_card_init_requested',
        route: '/NavBar',
        surface: 'feed',
        timestamp: now.subtract(const Duration(milliseconds: 200)),
        metadata: const <String, dynamic>{
          'docId': 'post-3',
          'dispatchIssued': false,
        },
      ),
    ]);

    final findings = recorder.buildPinpointFindings();

    expect(
      findings.any((item) => item.code == 'feed_duplicate_playback_dispatch'),
      isFalse,
    );
  });

  test('qa recorder drops resolved permission blockers from active findings',
      () {
    final recorder = QALabRecorder();
    final now = DateTime.now();

    recorder.lastPermissionStatuses['notifications'] = 'granted';
    recorder.issues.add(
      QALabIssue(
        id: 'perm_1',
        source: QALabIssueSource.permission,
        severity: QALabIssueSeverity.warning,
        code: 'permission_notifications_blocked',
        message: 'Notification permission is not granted.',
        timestamp: now,
        route: '/Settings',
        surface: 'settings',
      ),
    );

    final findings = recorder.buildPinpointFindings();
    expect(
      findings.any((item) => item.code == 'permission_notifications_blocked'),
      isFalse,
    );
  });

  test('qa recorder builds remote session document with device context',
      () async {
    final recorder = QALabRecorder();
    final now = DateTime.now();

    recorder.checkpoints.add(
      QALabCheckpoint(
        id: 'cp15',
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
    recorder.sessionId.value = 'session-1';
    recorder.startedAt.value = now.subtract(const Duration(seconds: 15));
    recorder.lastRoute.value = '/NavBar';
    recorder.lastSurface.value = 'feed';

    final remote = await recorder.buildRemoteSessionDocument(
      reason: 'unit_test',
      extendedDeviceInfoOverride: <String, dynamic>{
        'package': <String, dynamic>{
          'appName': 'TurqApp',
          'packageName': 'com.turqapp.app',
          'version': '1.1.4',
          'buildNumber': '14',
        },
        'device': <String, dynamic>{
          'manufacturer': 'Samsung',
          'model': 'SM-N986B',
          'sdkInt': 33,
        },
      },
    );

    final device =
        remote['device'] as Map<String, dynamic>? ?? <String, dynamic>{};
    final surfaces = remote['surfaceSummaries'] as Map<String, dynamic>? ??
        <String, dynamic>{};
    final feed =
        surfaces['feed'] as Map<String, dynamic>? ?? <String, dynamic>{};

    expect(remote['sessionId'], 'session-1');
    expect(device['model'], 'SM-N986B');
    expect((remote['app'] as Map<String, dynamic>)['packageName'],
        'com.turqapp.app');
    expect(feed['latestRoute'], '/NavBar');
    expect(feed['healthScore'], isNotNull);
  });

  test('qa recorder builds grouped remote occurrences with stable signature',
      () {
    final recorder = QALabRecorder();
    final now = DateTime.now();

    recorder.sessionId.value = 'session-2';
    recorder.startedAt.value = now.subtract(const Duration(seconds: 10));
    recorder.lastRoute.value = '/NavBar';
    recorder.lastSurface.value = 'feed';
    recorder.checkpoints.add(
      QALabCheckpoint(
        id: 'cp16',
        label: 'feed_runtime',
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
    );

    final occurrences = recorder.buildRemoteIssueOccurrences(
      sessionDocument: <String, dynamic>{
        'platform': 'android',
        'buildMode': 'release',
        'device': <String, dynamic>{'model': 'SM-N986B'},
        'app': <String, dynamic>{'version': '1.1.4'},
      },
    );

    final feedOccurrence = occurrences.firstWhere(
      (item) => item['surface'] == 'feed',
    );

    expect(feedOccurrence['signature'], isNotEmpty);
    expect(feedOccurrence['occurrenceId'], contains('session-2'));
    expect(feedOccurrence['route'], '/NavBar');
    expect(feedOccurrence['summary'], contains('feed'));
  });
}
