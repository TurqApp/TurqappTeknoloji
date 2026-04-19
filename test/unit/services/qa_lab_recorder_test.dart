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

    recorder.checkpoints.add(
      QALabCheckpoint(
        id: 'cp1',
        label: 'feed_visible',
        surface: 'feed',
        route: '/NavBar',
        timestamp: now,
        probe: <String, dynamic>{
          'navBar': <String, dynamic>{
            'registered': true,
            'selectedIndex': 0,
          },
          'feed': <String, dynamic>{
            'registered': true,
            'count': 1,
            'centeredIndex': 0,
            'centeredDocId': 'video-1',
            'centeredHasPlayableVideo': true,
            'centeredHasRenderableVideoCard': true,
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
            'currentPlayingDocID': 'feed:video-1',
            'targetPlaybackDocID': 'feed:video-1',
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

  test('qa recorder suppresses stale feed playback timeout findings', () {
    final recorder = QALabRecorder();
    final now = DateTime.now();

    recorder.checkpoints.add(
      QALabCheckpoint(
        id: 'cp_stale_feed_timeout',
        label: 'feed_visible',
        surface: 'feed',
        route: '/NavBarView',
        timestamp: now,
        probe: <String, dynamic>{
          'navBar': <String, dynamic>{
            'registered': true,
            'selectedIndex': 0,
          },
          'feed': <String, dynamic>{
            'registered': true,
            'count': 3,
            'centeredIndex': 2,
            'centeredDocId': 'video-2',
            'centeredHasPlayableVideo': false,
            'centeredHasRenderableVideoCard': false,
            'playbackSuspended': false,
            'pauseAll': false,
            'canClaimPlaybackNow': true,
          },
          'auth': <String, dynamic>{
            'currentUid': 'user-1',
            'isFirebaseSignedIn': true,
            'currentUserLoaded': true,
          },
          'videoPlayback': const <String, dynamic>{
            'registered': true,
            'currentPlayingDocID': '',
            'targetPlaybackDocID': '',
          },
        },
      ),
    );
    recorder.issues.addAll(<QALabIssue>[
      QALabIssue(
        id: 'stale_issue_started',
        source: QALabIssueSource.video,
        severity: QALabIssueSeverity.info,
        code: 'video_session_started',
        message: 'Video session started',
        timestamp: now.subtract(const Duration(seconds: 10)),
        route: '/NavBarView',
        surface: 'feed',
        metadata: const <String, dynamic>{
          'videoId': 'video-1',
        },
      ),
      QALabIssue(
        id: 'stale_issue_buffering',
        source: QALabIssueSource.video,
        severity: QALabIssueSeverity.info,
        code: 'video_buffering_started',
        message: 'Video buffering started',
        timestamp: now.subtract(const Duration(seconds: 8)),
        route: '/NavBarView',
        surface: 'feed',
        metadata: const <String, dynamic>{
          'videoId': 'video-1',
        },
      ),
    ]);

    final findings = recorder.buildPinpointFindings();

    expect(
      findings.any((item) => item.code == 'feed_first_frame_timeout'),
      isFalse,
    );
    expect(
      findings.any((item) => item.code == 'feed_buffer_stall'),
      isFalse,
    );
  });

  test('qa recorder flags authenticated short blank surface', () {
    final recorder = QALabRecorder();
    final now = DateTime.now();

    final probe = <String, dynamic>{
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
    };

    recorder.checkpoints.addAll(<QALabCheckpoint>[
      QALabCheckpoint(
        id: 'cp2a',
        label: 'short_loaded',
        surface: 'short',
        route: '/ShortView',
        timestamp: now.subtract(const Duration(seconds: 5)),
        probe: probe,
      ),
      QALabCheckpoint(
        id: 'cp2b',
        label: 'short_loaded',
        surface: 'short',
        route: '/ShortView',
        timestamp: now,
        probe: probe,
      ),
    ]);

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

  test(
      'qa recorder suppresses duplicate short visual slow warning when first frame is already slow',
      () {
    final recorder = QALabRecorder();
    final now = DateTime.now();
    final settleAt = now.subtract(const Duration(milliseconds: 3200));
    final firstFrameAt = settleAt.add(const Duration(milliseconds: 2811));
    const scrollToken = 'scroll-3';
    final probe = <String, dynamic>{
      'short': <String, dynamic>{
        'registered': true,
        'count': 5,
        'activeIndex': 4,
        'activeDocId': 'short-4',
      },
      'auth': <String, dynamic>{
        'currentUid': 'user-1',
        'isFirebaseSignedIn': true,
        'currentUserLoaded': true,
      },
      'videoPlayback': <String, dynamic>{
        'registered': true,
        'currentPlayingDocID': 'short:short-4',
        'targetPlaybackDocID': 'short:short-4',
      },
    };

    recorder.checkpoints.addAll(<QALabCheckpoint>[
      QALabCheckpoint(
        id: 'cp_short_visual_slow_old',
        label: 'short_runtime',
        surface: 'short',
        route: '/ShortView',
        timestamp: now.subtract(const Duration(seconds: 6)),
        probe: probe,
      ),
      QALabCheckpoint(
        id: 'cp_short_visual_slow',
        label: 'short_runtime',
        surface: 'short',
        route: '/ShortView',
        timestamp: now,
        probe: probe,
      ),
    ]);
    recorder.timelineEvents.addAll(<QALabTimelineEvent>[
      QALabTimelineEvent(
        id: 'short_settle_old_1',
        category: 'scroll',
        code: 'settled',
        route: '/ShortView',
        surface: 'short',
        timestamp: now.subtract(const Duration(seconds: 10)),
        metadata: const <String, dynamic>{
          'docId': 'short-1',
          'scrollToken': 'scroll-1',
        },
      ),
      QALabTimelineEvent(
        id: 'short_settle_old_2',
        category: 'scroll',
        code: 'settled',
        route: '/ShortView',
        surface: 'short',
        timestamp: now.subtract(const Duration(seconds: 7)),
        metadata: const <String, dynamic>{
          'docId': 'short-2',
          'scrollToken': 'scroll-2',
        },
      ),
      QALabTimelineEvent(
        id: 'short_settle_latest',
        category: 'scroll',
        code: 'settled',
        route: '/ShortView',
        surface: 'short',
        timestamp: settleAt,
        metadata: const <String, dynamic>{
          'docId': 'short-4',
          'scrollToken': scrollToken,
        },
      ),
      QALabTimelineEvent(
        id: 'short_dispatch_latest',
        category: 'playback_dispatch',
        code: 'short_page_play',
        route: '/ShortView',
        surface: 'short',
        timestamp: settleAt.add(const Duration(milliseconds: 120)),
        metadata: const <String, dynamic>{
          'docId': 'short-4',
          'dispatchIssued': true,
        },
      ),
    ]);
    recorder.issues.addAll(<QALabIssue>[
      QALabIssue(
        id: 'short_video_started',
        source: QALabIssueSource.video,
        severity: QALabIssueSeverity.info,
        code: 'video_session_started',
        message: 'Video session started',
        timestamp: settleAt.add(const Duration(milliseconds: 40)),
        route: '/ShortView',
        surface: 'short',
        metadata: const <String, dynamic>{
          'videoId': 'short-4',
        },
      ),
      QALabIssue(
        id: 'short_video_first_frame',
        source: QALabIssueSource.video,
        severity: QALabIssueSeverity.info,
        code: 'video_first_frame',
        message: 'Video rendered first frame',
        timestamp: firstFrameAt,
        route: '/ShortView',
        surface: 'short',
        metadata: const <String, dynamic>{
          'videoId': 'short-4',
        },
      ),
    ]);

    final findings = recorder.buildPinpointFindings();

    expect(
      findings.any((item) => item.code == 'short_scroll_first_frame_slow'),
      isTrue,
    );
    expect(
      findings.any((item) => item.code == 'short_transition_visual_slow'),
      isFalse,
    );
  });

  test(
      'qa recorder treats already-playing short skip as satisfied scroll dispatch',
      () {
    final recorder = QALabRecorder();
    final now = DateTime.now();
    final settleAt = now.subtract(const Duration(seconds: 3));
    const scrollToken = 'short-scroll-already-playing';
    final probe = <String, dynamic>{
      'short': <String, dynamic>{
        'registered': true,
        'count': 2,
        'activeIndex': 0,
        'activeDocId': 'short-1',
      },
      'auth': <String, dynamic>{
        'currentUid': 'user-1',
        'isFirebaseSignedIn': true,
        'currentUserLoaded': true,
      },
      'videoPlayback': <String, dynamic>{
        'registered': true,
        'currentPlayingDocID': 'short:short-1',
        'targetPlaybackDocID': 'short:short-1',
      },
    };

    recorder.checkpoints.addAll(<QALabCheckpoint>[
      QALabCheckpoint(
        id: 'cp_short_skip_old',
        label: 'short_runtime',
        surface: 'short',
        route: '/ShortView',
        timestamp: now.subtract(const Duration(seconds: 6)),
        probe: probe,
      ),
      QALabCheckpoint(
        id: 'cp_short_skip_now',
        label: 'short_runtime',
        surface: 'short',
        route: '/ShortView',
        timestamp: now,
        probe: probe,
      ),
    ]);
    recorder.timelineEvents.addAll(<QALabTimelineEvent>[
      QALabTimelineEvent(
        id: 'short_settle_skip',
        category: 'scroll',
        code: 'settled',
        route: '/ShortView',
        surface: 'short',
        timestamp: settleAt,
        metadata: const <String, dynamic>{
          'docId': 'short-1',
          'scrollToken': scrollToken,
        },
      ),
      QALabTimelineEvent(
        id: 'short_dispatch_skip',
        category: 'playback_dispatch',
        code: 'short_page_play_skipped',
        route: '/ShortView',
        surface: 'short',
        timestamp: settleAt.add(const Duration(milliseconds: 120)),
        metadata: const <String, dynamic>{
          'docId': 'short-1',
          'dispatchIssued': false,
          'dispatchSource': 'primary_already_playing',
          'callerSignature': 'primary_already_playing',
          'skipReason': 'already_playing',
          'scrollToken': scrollToken,
        },
      ),
    ]);

    final findings = recorder.buildPinpointFindings();

    expect(
      findings.any((item) => item.code == 'short_scroll_dispatch_timeout'),
      isFalse,
    );
  });

  test('qa recorder treats page-activated short target as satisfied dispatch',
      () {
    final recorder = QALabRecorder();
    final now = DateTime.now();
    final settleAt = now.subtract(const Duration(seconds: 3));
    const scrollToken = 'short-scroll-page-activated';
    final probe = <String, dynamic>{
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
        'currentPlayingDocID': 'short:short-2',
        'targetPlaybackDocID': 'short:short-2',
      },
    };

    recorder.checkpoints.addAll(<QALabCheckpoint>[
      QALabCheckpoint(
        id: 'cp_short_target_old',
        label: 'short_runtime',
        surface: 'short',
        route: '/ShortView',
        timestamp: now.subtract(const Duration(seconds: 6)),
        probe: probe,
      ),
      QALabCheckpoint(
        id: 'cp_short_target_now',
        label: 'short_runtime',
        surface: 'short',
        route: '/ShortView',
        timestamp: now,
        probe: probe,
      ),
    ]);
    recorder.timelineEvents.addAll(<QALabTimelineEvent>[
      QALabTimelineEvent(
        id: 'short_settle_target',
        category: 'scroll',
        code: 'settled',
        route: '/ShortView',
        surface: 'short',
        timestamp: settleAt,
        metadata: const <String, dynamic>{
          'docId': 'short-2',
          'scrollToken': scrollToken,
        },
      ),
      QALabTimelineEvent(
        id: 'short_dispatch_target',
        category: 'playback_dispatch',
        code: 'short_page_targeted',
        route: '/ShortView',
        surface: 'short',
        timestamp: settleAt.add(const Duration(milliseconds: 20)),
        metadata: const <String, dynamic>{
          'docId': 'short-2',
          'dispatchIssued': false,
          'dispatchSource': 'page_changed',
          'callerSignature': 'page_changed',
          'skipReason': 'page_activated',
          'scrollToken': scrollToken,
        },
      ),
    ]);

    final findings = recorder.buildPinpointFindings();

    expect(
      findings.any((item) => item.code == 'short_scroll_dispatch_timeout'),
      isFalse,
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
          metadata: <String, dynamic>{
            'errorType': i < 2 ? 'SocketException' : 'Choreographer',
          },
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
    final noiseFinding = feedDiagnostic.findings.firstWhere(
      (item) => item.code == 'feed_noise_burst',
    );
    final topFamilies =
        (feedDiagnostic.runtime['topSuppressedNoiseFamilies'] as List<dynamic>)
            .cast<Map<String, dynamic>>();
    final findingFamilies =
        (noiseFinding.context['topSuppressedNoiseFamilies'] as List<dynamic>)
            .cast<Map<String, dynamic>>();

    expect(feedDiagnostic.runtime['jankEventCount'], 1);
    expect(feedDiagnostic.runtime['suppressedNoiseCount'], 3);
    expect(topFamilies.first['family'], 'SocketException');
    expect(topFamilies.first['count'], 2);
    expect(findingFamilies.first['family'], 'SocketException');
    expect(findingFamilies.first['count'], 2);
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
        'centeredHasRenderableVideoCard': true,
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

  test(
      'qa recorder suppresses feed autoplay missing after unresolved lifecycle interruption',
      () {
    final recorder = QALabRecorder();
    final now = DateTime.now();
    final probe = <String, dynamic>{
      'feed': <String, dynamic>{
        'registered': true,
        'count': 2,
        'centeredIndex': 0,
        'centeredDocId': 'post-1',
        'centeredHasPlayableVideo': true,
        'centeredHasRenderableVideoCard': true,
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
        id: 'cp_feed_autoplay_interrupted_1',
        label: 'feed_visible',
        surface: 'feed',
        route: '/NavBar',
        timestamp: now.subtract(const Duration(seconds: 5)),
        probe: probe,
      ),
      QALabCheckpoint(
        id: 'cp_feed_autoplay_interrupted_2',
        label: 'feed_watchdog',
        surface: 'feed',
        route: '/NavBar',
        timestamp: now,
        probe: probe,
      ),
    ]);
    recorder.issues.addAll(<QALabIssue>[
      QALabIssue(
        id: 'issue_lifecycle_inactive_autoplay',
        source: QALabIssueSource.lifecycle,
        severity: QALabIssueSeverity.info,
        code: 'lifecycle_inactive',
        message: 'Application lifecycle changed to inactive.',
        timestamp: now.subtract(const Duration(seconds: 4)),
        route: '/NavBar',
        surface: 'feed',
      ),
      QALabIssue(
        id: 'issue_lifecycle_pause_autoplay',
        source: QALabIssueSource.lifecycle,
        severity: QALabIssueSeverity.info,
        code: 'lifecycle_pause',
        message: 'Application lifecycle changed to pause.',
        timestamp: now.subtract(const Duration(seconds: 3)),
        route: '/NavBar',
        surface: 'feed',
      ),
    ]);

    final findings = recorder.buildPinpointFindings();

    expect(
      findings.any((item) => item.code == 'feed_autoplay_missing'),
      isFalse,
    );
  });

  test('qa recorder suppresses feed playback gate during autostart warmup', () {
    final recorder = QALabRecorder();
    final now = DateTime.now();
    recorder.startedAt.value = now.subtract(const Duration(seconds: 4));

    recorder.checkpoints.add(
      QALabCheckpoint(
        id: 'cp_gate_warmup',
        label: 'feed_runtime',
        surface: 'feed',
        route: '/NavBarView',
        timestamp: now,
        probe: <String, dynamic>{
          'navBar': <String, dynamic>{
            'registered': true,
            'selectedIndex': 0,
          },
          'feed': <String, dynamic>{
            'registered': true,
            'count': 2,
            'centeredIndex': 0,
            'centeredDocId': 'post-1',
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
      findings.any((item) => item.code == 'feed_playback_gate_blocked'),
      isFalse,
    );
  });

  test('qa recorder still flags feed playback gate after warmup', () {
    final recorder = QALabRecorder();
    final now = DateTime.now();
    recorder.startedAt.value = now.subtract(const Duration(seconds: 35));

    recorder.checkpoints.add(
      QALabCheckpoint(
        id: 'cp_gate_post_warmup',
        label: 'feed_runtime',
        surface: 'feed',
        route: '/NavBarView',
        timestamp: now,
        probe: <String, dynamic>{
          'navBar': <String, dynamic>{
            'registered': true,
            'selectedIndex': 0,
          },
          'feed': <String, dynamic>{
            'registered': true,
            'count': 2,
            'centeredIndex': 0,
            'centeredDocId': 'post-1',
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
      findings.any((item) => item.code == 'feed_playback_gate_blocked'),
      isTrue,
    );
  });

  test('qa recorder suppresses feed autoplay findings off the feed tab', () {
    final recorder = QALabRecorder();
    final now = DateTime.now();
    final probe = <String, dynamic>{
      'navBar': <String, dynamic>{
        'registered': true,
        'selectedIndex': 1,
      },
      'feed': <String, dynamic>{
        'registered': true,
        'count': 2,
        'centeredIndex': 0,
        'centeredDocId': 'post-1',
        'centeredHasPlayableVideo': true,
        'centeredHasRenderableVideoCard': true,
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
        id: 'cp_feed_bg_autoplay_1',
        label: 'feed_background',
        surface: 'feed',
        route: '/NavBarView',
        timestamp: now.subtract(const Duration(seconds: 5)),
        probe: probe,
      ),
      QALabCheckpoint(
        id: 'cp_feed_bg_autoplay_2',
        label: 'feed_background',
        surface: 'feed',
        route: '/NavBarView',
        timestamp: now,
        probe: probe,
      ),
    ]);

    final findings = recorder.buildPinpointFindings();

    expect(
      findings.any((item) => item.code == 'feed_autoplay_missing'),
      isFalse,
    );
    expect(
      findings.any((item) => item.code == 'feed_autoplay_wrong_target'),
      isFalse,
    );
  });

  test('qa recorder suppresses invalid centered feed state off the feed tab',
      () {
    final recorder = QALabRecorder();
    final now = DateTime.now();

    recorder.checkpoints.add(
      QALabCheckpoint(
        id: 'cp_feed_bg_state',
        label: 'feed_background',
        surface: 'feed',
        route: '/NavBarView',
        timestamp: now,
        probe: <String, dynamic>{
          'navBar': <String, dynamic>{
            'registered': true,
            'selectedIndex': 3,
          },
          'feed': <String, dynamic>{
            'registered': true,
            'count': 2,
            'centeredIndex': -1,
            'centeredDocId': 'post-1',
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

  test(
    'qa recorder suppresses invalid centered feed state after recent lifecycle interruption',
    () {
      final recorder = QALabRecorder();
      final now = DateTime.now();

      recorder.checkpoints.add(
        QALabCheckpoint(
          id: 'cp_feed_recent_lifecycle_state',
          label: 'feed_recent_lifecycle',
          surface: 'feed',
          route: '/NavBarView',
          timestamp: now,
          probe: <String, dynamic>{
            'navBar': <String, dynamic>{
              'registered': true,
              'selectedIndex': 0,
            },
            'feed': <String, dynamic>{
              'registered': true,
              'count': 2,
              'centeredIndex': -1,
              'centeredDocId': '',
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
          id: 'issue_recent_lifecycle_pause',
          source: QALabIssueSource.lifecycle,
          severity: QALabIssueSeverity.info,
          code: 'lifecycle_pause',
          message: 'Application lifecycle changed to pause.',
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
    },
  );

  test('qa recorder builds surface alert summaries with blockers first', () {
    final recorder = QALabRecorder();
    final now = DateTime.now();
    final feedBlankProbe = <String, dynamic>{
      'feed': <String, dynamic>{
        'registered': true,
        'count': 0,
      },
      'auth': <String, dynamic>{
        'currentUid': 'user-1',
        'isFirebaseSignedIn': true,
        'currentUserLoaded': true,
      },
    };

    recorder.checkpoints.addAll(<QALabCheckpoint>[
      QALabCheckpoint(
        id: 'cp6a',
        label: 'feed_loaded',
        surface: 'feed',
        route: '/NavBar',
        timestamp: now.subtract(const Duration(seconds: 5)),
        probe: feedBlankProbe,
      ),
      QALabCheckpoint(
        id: 'cp6b',
        label: 'feed_loaded',
        surface: 'feed',
        route: '/NavBar',
        timestamp: now,
        probe: feedBlankProbe,
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
        'centeredHasPlayableVideo': true,
        'centeredHasRenderableVideoCard': true,
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

  test(
      'qa recorder suppresses native first-frame timeout during autostart warmup',
      () {
    final recorder = QALabRecorder();
    final now = DateTime.now();
    recorder.startedAt.value = now.subtract(const Duration(seconds: 4));

    recorder.checkpoints.add(
      QALabCheckpoint(
        id: 'cp_native_warmup',
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
        'platform': 'android',
        'status': 'FIRST_FRAME_TIMEOUT',
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

  test(
      'qa recorder suppresses native first-frame timeout while background recovery is pending',
      () {
    final recorder = QALabRecorder();
    final now = DateTime.now();

    recorder.checkpoints.add(
      QALabCheckpoint(
        id: 'cp_native_background_wait',
        label: 'feed_runtime',
        surface: 'feed',
        route: '/NavBarView',
        timestamp: now,
        probe: <String, dynamic>{
          'navBar': <String, dynamic>{
            'registered': true,
            'selectedIndex': 0,
          },
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
        'platform': 'android',
        'status': 'FIRST_FRAME_TIMEOUT|PLAYBACK_NOT_STARTED',
        'errors': const <String>['FIRST_FRAME_TIMEOUT', 'PLAYBACK_NOT_STARTED'],
        'active': true,
        'firstFrameRendered': false,
        'isPlaybackExpected': true,
        'isPlaying': false,
        'isBuffering': false,
        'stallCount': 0,
        'layerAttachCount': 0,
        'lastKnownPlaybackTime': 0.0,
        'sampledAt': now.toUtc().toIso8601String(),
        'trigger': 'test',
        'supported': true,
        'awaitingBackgroundRecovery': true,
        'snapshot': <String, dynamic>{
          'awaitingBackgroundRecovery': true,
          'appBackgroundedAt': 100,
          'appForegroundedAt': 0,
          'appDidEnterBackgroundAt': 100,
          'appWillEnterForegroundAt': 0,
        },
      });

    final findings = recorder.buildPinpointFindings();

    expect(
      findings.any((item) => item.code == 'feed_native_first_frame_timeout'),
      isFalse,
    );
  });

  test('qa recorder suppresses native short timeout off the short tab', () {
    final recorder = QALabRecorder();
    final now = DateTime.now();

    recorder.checkpoints.add(
      QALabCheckpoint(
        id: 'cp_short_off_tab',
        label: 'short_runtime',
        surface: 'short',
        route: '/SignIn',
        timestamp: now,
        probe: <String, dynamic>{
          'navBar': <String, dynamic>{
            'registered': true,
            'selectedIndex': 0,
          },
          'short': <String, dynamic>{
            'registered': true,
            'count': 1,
            'activeIndex': 0,
            'activeDocId': 'short-1',
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
        'layerAttachCount': 0,
        'lastKnownPlaybackTime': 0.0,
        'sampledAt': now.toUtc().toIso8601String(),
        'trigger': 'test',
        'supported': true,
      });

    final findings = recorder.buildPinpointFindings();

    expect(
      findings.any((item) => item.code == 'short_native_first_frame_timeout'),
      isFalse,
    );
  });

  test('qa recorder suppresses feed thumbnail runtime loss off the feed tab',
      () {
    final recorder = QALabRecorder();
    final now = DateTime.now();

    recorder.checkpoints.add(
      QALabCheckpoint(
        id: 'cp_native_background',
        label: 'feed_background',
        surface: 'feed',
        route: '/NavBarView',
        timestamp: now,
        probe: <String, dynamic>{
          'navBar': <String, dynamic>{
            'registered': true,
            'selectedIndex': 1,
          },
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
    recorder.issues.addAll(<QALabIssue>[
      QALabIssue(
        id: 'ff_1',
        source: QALabIssueSource.video,
        severity: QALabIssueSeverity.info,
        code: 'video_first_frame',
        message: 'first frame',
        timestamp: now.subtract(const Duration(seconds: 2)),
        route: '/NavBarView',
        surface: 'feed',
        metadata: const <String, dynamic>{'videoId': 'post-1'},
      ),
      QALabIssue(
        id: 'ff_2',
        source: QALabIssueSource.video,
        severity: QALabIssueSeverity.info,
        code: 'video_first_frame',
        message: 'first frame',
        timestamp: now.subtract(const Duration(seconds: 1)),
        route: '/NavBarView',
        surface: 'feed',
        metadata: const <String, dynamic>{'videoId': 'post-1'},
      ),
    ]);
    recorder.lastNativePlaybackSnapshot
      ..clear()
      ..addAll(<String, dynamic>{
        'platform': 'android',
        'status': 'READY_WITHOUT_FRAME',
        'errors': const <String>[],
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
      findings.any((item) => item.code == 'feed_thumbnail_only_runtime_loss'),
      isFalse,
    );
  });

  test(
      'qa recorder suppresses feed playback timeout and stall after unresolved lifecycle interruption',
      () {
    final recorder = QALabRecorder();
    final now = DateTime.now();
    final probe = <String, dynamic>{
      'navBar': <String, dynamic>{
        'registered': true,
        'selectedIndex': 0,
      },
      'feed': <String, dynamic>{
        'registered': true,
        'count': 2,
        'centeredIndex': 0,
        'centeredDocId': 'post-1',
        'centeredHasPlayableVideo': true,
        'centeredHasRenderableVideoCard': true,
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
        'currentPlayingDocID': 'feed:post-1',
        'targetPlaybackDocID': 'feed:post-1',
      },
    };

    recorder.checkpoints.add(
      QALabCheckpoint(
        id: 'cp_feed_lifecycle_interrupted',
        label: 'feed_runtime',
        surface: 'feed',
        route: '/NavBarView',
        timestamp: now,
        probe: probe,
      ),
    );
    recorder.issues.addAll(<QALabIssue>[
      QALabIssue(
        id: 'issue_session_started',
        source: QALabIssueSource.video,
        severity: QALabIssueSeverity.info,
        code: 'video_session_started',
        message: 'Video session started',
        timestamp: now.subtract(const Duration(seconds: 12)),
        route: '/NavBarView',
        surface: 'feed',
        metadata: const <String, dynamic>{'videoId': 'post-1'},
      ),
      QALabIssue(
        id: 'issue_buffering_started',
        source: QALabIssueSource.video,
        severity: QALabIssueSeverity.info,
        code: 'video_buffering_started',
        message: 'Video buffering started',
        timestamp: now.subtract(const Duration(seconds: 11)),
        route: '/NavBarView',
        surface: 'feed',
        metadata: const <String, dynamic>{'videoId': 'post-1'},
      ),
      QALabIssue(
        id: 'issue_lifecycle_inactive',
        source: QALabIssueSource.lifecycle,
        severity: QALabIssueSeverity.info,
        code: 'lifecycle_inactive',
        message: 'Application lifecycle changed to inactive.',
        timestamp: now.subtract(const Duration(seconds: 10)),
        route: '/NavBarView',
        surface: 'feed',
      ),
      QALabIssue(
        id: 'issue_lifecycle_pause',
        source: QALabIssueSource.lifecycle,
        severity: QALabIssueSeverity.info,
        code: 'lifecycle_pause',
        message: 'Application lifecycle changed to pause.',
        timestamp: now.subtract(const Duration(seconds: 9)),
        route: '/NavBarView',
        surface: 'feed',
      ),
    ]);

    final findings = recorder.buildPinpointFindings();

    expect(
      findings.any((item) => item.code == 'feed_first_frame_timeout'),
      isFalse,
    );
    expect(
      findings.any((item) => item.code == 'feed_buffer_stall'),
      isFalse,
    );
  });

  test(
      'qa recorder suppresses native feed runtime findings after recent unresolved lifecycle interruption',
      () {
    final recorder = QALabRecorder();
    final now = DateTime.now();
    final probe = <String, dynamic>{
      'navBar': <String, dynamic>{
        'registered': true,
        'selectedIndex': 0,
      },
      'feed': <String, dynamic>{
        'registered': true,
        'count': 2,
        'centeredIndex': 0,
        'centeredDocId': 'post-1',
        'centeredHasPlayableVideo': true,
        'centeredHasRenderableVideoCard': true,
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
        'currentPlayingDocID': 'feed:post-1',
        'targetPlaybackDocID': 'feed:post-1',
      },
    };

    recorder.checkpoints.add(
      QALabCheckpoint(
        id: 'cp_feed_native_interrupted',
        label: 'feed_runtime',
        surface: 'feed',
        route: '/NavBarView',
        timestamp: now,
        probe: probe,
      ),
    );
    recorder.issues.addAll(<QALabIssue>[
      QALabIssue(
        id: 'ff_native_1',
        source: QALabIssueSource.video,
        severity: QALabIssueSeverity.info,
        code: 'video_first_frame',
        message: 'first frame',
        timestamp: now.subtract(const Duration(seconds: 2)),
        route: '/NavBarView',
        surface: 'feed',
        metadata: const <String, dynamic>{'videoId': 'post-1'},
      ),
      QALabIssue(
        id: 'ff_native_2',
        source: QALabIssueSource.video,
        severity: QALabIssueSeverity.info,
        code: 'video_first_frame',
        message: 'first frame',
        timestamp: now.subtract(const Duration(seconds: 1)),
        route: '/NavBarView',
        surface: 'feed',
        metadata: const <String, dynamic>{'videoId': 'post-1'},
      ),
      QALabIssue(
        id: 'issue_lifecycle_inactive_native',
        source: QALabIssueSource.lifecycle,
        severity: QALabIssueSeverity.info,
        code: 'lifecycle_inactive',
        message: 'Application lifecycle changed to inactive.',
        timestamp: now.subtract(const Duration(seconds: 4)),
        route: '/NavBarView',
        surface: 'feed',
      ),
      QALabIssue(
        id: 'issue_lifecycle_pause_native',
        source: QALabIssueSource.lifecycle,
        severity: QALabIssueSeverity.info,
        code: 'lifecycle_pause',
        message: 'Application lifecycle changed to pause.',
        timestamp: now.subtract(const Duration(seconds: 3)),
        route: '/NavBarView',
        surface: 'feed',
      ),
    ]);
    recorder.lastNativePlaybackSnapshot
      ..clear()
      ..addAll(<String, dynamic>{
        'platform': 'android',
        'status': 'READY_WITHOUT_FRAME',
        'errors': const <String>[
          'FIRST_FRAME_TIMEOUT',
          'EXCESSIVE_REBUFFERING'
        ],
        'active': true,
        'firstFrameRendered': false,
        'isPlaybackExpected': true,
        'isPlaying': false,
        'isBuffering': true,
        'stallCount': 3,
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
    expect(
      findings.any((item) => item.code == 'feed_native_buffer_stall'),
      isFalse,
    );
    expect(
      findings.any((item) => item.code == 'feed_thumbnail_only_runtime_loss'),
      isFalse,
    );
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

  test('qa recorder ignores feed refetch after previous request settled', () {
    final recorder = QALabRecorder();
    final now = DateTime.now();

    recorder.checkpoints.add(
      QALabCheckpoint(
        id: 'cp_feed_settled',
        label: 'feed_runtime',
        surface: 'feed',
        route: '/NavBar',
        timestamp: now,
        probe: <String, dynamic>{
          'feed': <String, dynamic>{
            'registered': true,
            'count': 4,
            'centeredIndex': 0,
            'centeredDocId': 'post-1',
            'centeredHasPlayableVideo': true,
            'centeredHasRenderableVideoCard': true,
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
        id: 'tfr1',
        category: 'feed_fetch',
        code: 'requested',
        route: '/NavBar',
        surface: 'feed',
        timestamp: now.subtract(const Duration(milliseconds: 900)),
        metadata: const <String, dynamic>{'trigger': 'scroll_near_end'},
      ),
      QALabTimelineEvent(
        id: 'tfr2',
        category: 'feed_fetch',
        code: 'started',
        route: '/NavBar',
        surface: 'feed',
        timestamp: now.subtract(const Duration(milliseconds: 780)),
        metadata: const <String, dynamic>{'trigger': 'scroll_near_end'},
      ),
      QALabTimelineEvent(
        id: 'tfr3',
        category: 'feed_fetch',
        code: 'completed',
        route: '/NavBar',
        surface: 'feed',
        timestamp: now.subtract(const Duration(milliseconds: 620)),
        metadata: const <String, dynamic>{'trigger': 'scroll_near_end'},
      ),
      QALabTimelineEvent(
        id: 'tfr4',
        category: 'feed_fetch',
        code: 'requested',
        route: '/NavBar',
        surface: 'feed',
        timestamp: now.subtract(const Duration(milliseconds: 300)),
        metadata: const <String, dynamic>{'trigger': 'scroll_near_end'},
      ),
    ]);

    final findings = recorder.buildPinpointFindings();

    expect(
      findings.any((item) => item.code == 'feed_duplicate_fetch_trigger'),
      isFalse,
    );
  });

  test('qa recorder flags short duplicate fetch triggers', () {
    final recorder = QALabRecorder();
    final now = DateTime.now();

    recorder.checkpoints.add(
      QALabCheckpoint(
        id: 'cp_short_fetch',
        label: 'short_runtime',
        surface: 'short',
        route: '/ShortView',
        timestamp: now,
        probe: <String, dynamic>{
          'short': <String, dynamic>{
            'registered': true,
            'count': 4,
            'activeIndex': 0,
            'activeDocId': 'short-1',
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
        id: 'short_fetch_1',
        category: 'feed_fetch',
        code: 'requested',
        route: '/ShortView',
        surface: 'short',
        timestamp: now.subtract(const Duration(milliseconds: 700)),
        metadata: const <String, dynamic>{'trigger': 'scroll_near_end'},
      ),
      QALabTimelineEvent(
        id: 'short_fetch_2',
        category: 'feed_fetch',
        code: 'started',
        route: '/ShortView',
        surface: 'short',
        timestamp: now.subtract(const Duration(milliseconds: 500)),
        metadata: const <String, dynamic>{'trigger': 'scroll_near_end'},
      ),
      QALabTimelineEvent(
        id: 'short_fetch_3',
        category: 'feed_fetch',
        code: 'requested',
        route: '/ShortView',
        surface: 'short',
        timestamp: now.subtract(const Duration(milliseconds: 250)),
        metadata: const <String, dynamic>{'trigger': 'scroll_near_end'},
      ),
    ]);

    final findings = recorder.buildPinpointFindings();

    expect(
      findings.any((item) => item.code == 'short_duplicate_fetch_trigger'),
      isTrue,
    );
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

  test('qa recorder flags feed video source not ready after grace window', () {
    final recorder = QALabRecorder();
    final now = DateTime.now();
    final probe = <String, dynamic>{
      'feed': <String, dynamic>{
        'registered': true,
        'count': 1,
        'centeredIndex': 0,
        'centeredDocId': 'post-hls-1',
        'centeredHasPlayableVideo': false,
        'centeredHasRenderableVideoCard': true,
        'playbackSuspended': false,
        'pauseAll': false,
        'canClaimPlaybackNow': true,
      },
      'auth': <String, dynamic>{
        'currentUid': 'user-1',
        'isFirebaseSignedIn': true,
        'currentUserLoaded': true,
      },
    };

    recorder.checkpoints.addAll(<QALabCheckpoint>[
      QALabCheckpoint(
        id: 'cp_hls_1',
        label: 'feed_visible',
        surface: 'feed',
        route: '/NavBar',
        timestamp: now.subtract(const Duration(seconds: 5)),
        probe: probe,
      ),
      QALabCheckpoint(
        id: 'cp_hls_2',
        label: 'feed_watchdog',
        surface: 'feed',
        route: '/NavBar',
        timestamp: now,
        probe: probe,
      ),
    ]);

    final findings = recorder.buildPinpointFindings();
    final summaries = recorder.buildSurfaceAlertSummaries();
    final feedSummary = summaries.firstWhere((item) => item.surface == 'feed');

    expect(
      findings.any((item) => item.code == 'feed_video_source_not_ready'),
      isTrue,
    );
    expect(feedSummary.primaryRootCauseCategory, 'media_pipeline');
  });

  test('qa recorder flags short source-not-ready fetch observations', () {
    final recorder = QALabRecorder();
    final now = DateTime.now();

    recorder.checkpoints.add(
      QALabCheckpoint(
        id: 'cp_short_source',
        label: 'short_runtime',
        surface: 'short',
        route: '/ShortView',
        timestamp: now,
        probe: <String, dynamic>{
          'short': <String, dynamic>{
            'registered': true,
            'count': 0,
            'activeIndex': -1,
            'activeDocId': '',
          },
          'auth': <String, dynamic>{
            'currentUid': 'user-1',
            'isFirebaseSignedIn': true,
            'currentUserLoaded': true,
          },
        },
      ),
    );
    recorder.timelineEvents.add(
      QALabTimelineEvent(
        id: 'short_source_1',
        category: 'feed_fetch',
        code: 'source_not_ready',
        route: '/ShortView',
        surface: 'short',
        timestamp: now.subtract(const Duration(milliseconds: 200)),
        metadata: const <String, dynamic>{
          'trigger': 'scroll_near_end',
          'count': 2,
          'docIds': <String>['short-hls-1', 'short-hls-2'],
          'hlsStatuses': <String>['processing', 'pending'],
        },
      ),
    );

    final findings = recorder.buildPinpointFindings();
    final shortFinding = findings.firstWhere(
      (item) => item.code == 'short_video_source_not_ready',
    );

    expect(shortFinding.context['count'], 2);
    expect(
      shortFinding.context['docIds'],
      const <String>['short-hls-1', 'short-hls-2'],
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

  test(
      'qa recorder suppresses stale feed scroll dispatch timeout when centered doc moved',
      () {
    final recorder = QALabRecorder();
    final now = DateTime.now();

    recorder.checkpoints.add(
      QALabCheckpoint(
        id: 'cp15b',
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
            'centeredHasPlayableVideo': true,
            'centeredHasRenderableVideoCard': true,
            'playbackSuspended': false,
            'pauseAll': false,
            'canClaimPlaybackNow': true,
          },
          'navBar': <String, dynamic>{
            'registered': true,
            'selectedIndex': 0,
          },
          'auth': <String, dynamic>{
            'currentUid': 'user-1',
            'isFirebaseSignedIn': true,
            'currentUserLoaded': true,
          },
        },
      ),
    );
    recorder.timelineEvents.add(
      QALabTimelineEvent(
        id: 'ts2b',
        category: 'scroll',
        code: 'settled',
        route: '/NavBar',
        surface: 'feed',
        timestamp: now.subtract(const Duration(seconds: 70)),
        metadata: const <String, dynamic>{
          'docId': 'post-1',
          'scrollToken': 'feed-scroll-stale',
        },
      ),
    );

    final findings = recorder.buildPinpointFindings();

    expect(
      findings.any((item) => item.code == 'feed_scroll_dispatch_timeout'),
      isFalse,
    );
  });

  test(
      'qa recorder suppresses feed scroll dispatch timeout when centered item is no longer autoplay eligible',
      () {
    final recorder = QALabRecorder();
    final now = DateTime.now();

    recorder.checkpoints.add(
      QALabCheckpoint(
        id: 'cp15c',
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
            'centeredHasPlayableVideo': false,
            'centeredHasRenderableVideoCard': false,
            'playbackSuspended': false,
            'pauseAll': false,
            'canClaimPlaybackNow': true,
          },
          'navBar': <String, dynamic>{
            'registered': true,
            'selectedIndex': 0,
          },
          'auth': <String, dynamic>{
            'currentUid': 'user-1',
            'isFirebaseSignedIn': true,
            'currentUserLoaded': true,
          },
        },
      ),
    );
    recorder.timelineEvents.add(
      QALabTimelineEvent(
        id: 'ts2c',
        category: 'scroll',
        code: 'settled',
        route: '/NavBar',
        surface: 'feed',
        timestamp: now.subtract(const Duration(seconds: 70)),
        metadata: const <String, dynamic>{
          'docId': 'post-1',
          'scrollToken': 'feed-scroll-non-playable',
        },
      ),
    );

    final findings = recorder.buildPinpointFindings();

    expect(
      findings.any((item) => item.code == 'feed_scroll_dispatch_timeout'),
      isFalse,
    );
  });

  test(
      'qa recorder treats manager resume current as satisfied feed scroll dispatch',
      () {
    final recorder = QALabRecorder();
    final now = DateTime.now();

    recorder.checkpoints.add(
      QALabCheckpoint(
        id: 'cp15d',
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
            'centeredHasPlayableVideo': true,
            'centeredHasRenderableVideoCard': true,
            'playbackSuspended': false,
            'pauseAll': false,
            'canClaimPlaybackNow': true,
          },
          'navBar': <String, dynamic>{
            'registered': true,
            'selectedIndex': 0,
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
        id: 'ts2d',
        category: 'scroll',
        code: 'settled',
        route: '/NavBar',
        surface: 'feed',
        timestamp: now.subtract(const Duration(seconds: 3)),
        metadata: const <String, dynamic>{
          'docId': 'post-1',
          'scrollToken': 'feed-scroll-resume-current',
        },
      ),
      QALabTimelineEvent(
        id: 'tp4d',
        category: 'playback_dispatch',
        code: 'feed_card_manager_resume_current',
        route: '/NavBar',
        surface: 'feed',
        timestamp: now.subtract(const Duration(seconds: 2)),
        metadata: const <String, dynamic>{
          'docId': 'post-1',
          'dispatchIssued': false,
          'dispatchSource': 'video_initialized',
          'callerSignature': 'video_initialized',
          'skipReason': '',
          'scrollToken': 'feed-scroll-resume-current',
        },
      ),
    ]);

    final findings = recorder.buildPinpointFindings();

    expect(
      findings.any((item) => item.code == 'feed_scroll_dispatch_timeout'),
      isFalse,
    );
  });

  test(
      'qa recorder suppresses feed scroll dispatch timeout when playback already targets settled doc',
      () {
    final recorder = QALabRecorder();
    final now = DateTime.now();

    recorder.checkpoints.add(
      QALabCheckpoint(
        id: 'cp15e',
        label: 'feed_runtime',
        surface: 'feed',
        route: '/NavBar',
        timestamp: now,
        probe: <String, dynamic>{
          'feed': <String, dynamic>{
            'registered': true,
            'count': 3,
            'centeredIndex': 2,
            'centeredDocId': 'post-3',
            'centeredHasPlayableVideo': true,
            'centeredHasRenderableVideoCard': true,
            'playbackSuspended': false,
            'pauseAll': false,
            'canClaimPlaybackNow': true,
          },
          'navBar': <String, dynamic>{
            'registered': true,
            'selectedIndex': 0,
          },
          'auth': <String, dynamic>{
            'currentUid': 'user-1',
            'isFirebaseSignedIn': true,
            'currentUserLoaded': true,
          },
          'videoPlayback': <String, dynamic>{
            'registered': true,
            'currentPlayingDocID': 'feed:post-3',
            'targetPlaybackDocID': 'feed:post-3',
          },
        },
      ),
    );
    recorder.timelineEvents.add(
      QALabTimelineEvent(
        id: 'ts2e',
        category: 'scroll',
        code: 'settled',
        route: '/NavBar',
        surface: 'feed',
        timestamp: now.subtract(const Duration(seconds: 3)),
        metadata: <String, dynamic>{
          'docId': 'post-3',
          'scrollToken': 'feed-scroll-pretargeted',
          'probe': <String, dynamic>{
            'feed': <String, dynamic>{
              'registered': true,
              'count': 3,
              'centeredIndex': 2,
              'centeredDocId': 'post-3',
              'centeredHasPlayableVideo': true,
              'centeredHasRenderableVideoCard': true,
              'playbackSuspended': false,
              'pauseAll': false,
              'canClaimPlaybackNow': true,
            },
            'videoPlayback': <String, dynamic>{
              'registered': true,
              'currentPlayingDocID': 'feed:post-3',
              'targetPlaybackDocID': 'feed:post-3',
            },
          },
        },
      ),
    );

    final findings = recorder.buildPinpointFindings();

    expect(
      findings.any((item) => item.code == 'feed_scroll_dispatch_timeout'),
      isFalse,
    );
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
        timestamp: now.subtract(const Duration(seconds: 5)),
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

  test('qa recorder flags short playback retry burst after settle', () {
    final recorder = QALabRecorder();
    final now = DateTime.now();

    recorder.checkpoints.add(
      QALabCheckpoint(
        id: 'cp_short_retry',
        label: 'short_runtime',
        surface: 'short',
        route: '/ShortView',
        timestamp: now,
        probe: <String, dynamic>{
          'short': <String, dynamic>{
            'registered': true,
            'count': 2,
            'activeIndex': 0,
            'activeDocId': 'short-1',
          },
          'auth': <String, dynamic>{
            'currentUid': 'user-1',
            'isFirebaseSignedIn': true,
            'currentUserLoaded': true,
          },
          'videoPlayback': <String, dynamic>{
            'registered': true,
            'currentPlayingDocID': 'short-1',
            'registeredHandleCount': 1,
            'savedStateCount': 0,
          },
        },
      ),
    );
    recorder.timelineEvents.addAll(<QALabTimelineEvent>[
      QALabTimelineEvent(
        id: 'short_settle_retry',
        category: 'scroll',
        code: 'settled',
        route: '/ShortView',
        surface: 'short',
        timestamp: now.subtract(const Duration(seconds: 3)),
        metadata: const <String, dynamic>{'docId': 'short-1'},
      ),
      QALabTimelineEvent(
        id: 'short_retry_1',
        category: 'playback_dispatch',
        code: 'short_watchdog_play_retry',
        route: '/ShortView',
        surface: 'short',
        timestamp: now.subtract(const Duration(milliseconds: 1800)),
        metadata: const <String, dynamic>{
          'docId': 'short-1',
          'retry': 1,
        },
      ),
      QALabTimelineEvent(
        id: 'short_retry_2',
        category: 'playback_dispatch',
        code: 'short_watchdog_play_retry',
        route: '/ShortView',
        surface: 'short',
        timestamp: now.subtract(const Duration(milliseconds: 400)),
        metadata: const <String, dynamic>{
          'docId': 'short-1',
          'retry': 2,
        },
      ),
    ]);

    final findings = recorder.buildPinpointFindings();

    expect(
      findings.any((item) => item.code == 'short_playback_retry_burst'),
      isTrue,
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
    final feedProbe = <String, dynamic>{
      'feed': <String, dynamic>{
        'registered': true,
        'count': 0,
      },
      'auth': <String, dynamic>{
        'currentUid': 'user-1',
        'isFirebaseSignedIn': true,
        'currentUserLoaded': true,
      },
    };
    recorder.checkpoints.addAll(<QALabCheckpoint>[
      QALabCheckpoint(
        id: 'cp16a',
        label: 'feed_runtime',
        surface: 'feed',
        route: '/NavBar',
        timestamp: now.subtract(const Duration(seconds: 10)),
        probe: feedProbe,
      ),
      QALabCheckpoint(
        id: 'cp16b',
        label: 'feed_runtime',
        surface: 'feed',
        route: '/NavBar',
        timestamp: now,
        probe: feedProbe,
      ),
    ]);
    recorder.issues.addAll(<QALabIssue>[
      for (var i = 0; i < 3; i += 1)
        QALabIssue(
          id: 'feed_noise_$i',
          source: QALabIssueSource.platform,
          severity: QALabIssueSeverity.info,
          code: 'platform_suppressed',
          message: 'suppressed noise',
          timestamp: now.subtract(Duration(seconds: i + 1)),
          route: '/NavBar',
          surface: 'feed',
          metadata: <String, dynamic>{
            'errorType': 'SocketException',
          },
        ),
    ]);

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
