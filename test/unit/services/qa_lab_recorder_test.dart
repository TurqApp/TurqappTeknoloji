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
}
