import 'package:flutter_test/flutter_test.dart';
import 'package:turqappv2/Core/Services/integration_smoke_reporter.dart';

void main() {
  test('builds summary from smoke artifacts', () {
    final report = IntegrationSmokeReporter.buildReport(
      <Map<String, dynamic>>[
        <String, dynamic>{
          'scenario': 'feed_resume',
          'probe': <String, dynamic>{
            'currentRoute': '/feed',
            'previousRoute': '/profile',
          },
          'telemetry': <String, dynamic>{
            'thresholdReport': <String, dynamic>{
              'issues': <Map<String, dynamic>>[
                <String, dynamic>{'severity': 'blocking'},
                <String, dynamic>{'severity': 'warning'},
              ],
            },
          },
          'artifactStatus': <String, dynamic>{
            'exported': true,
            'reason': '',
          },
          'invariants': <String, dynamic>{'count': 1},
          'failure': <String, dynamic>{'screenshotPath': 'x.png'},
          'deviceLog': <String, dynamic>{
            'summary': <String, dynamic>{
              'issueCount': 2,
              'blockingCount': 1,
            },
          },
        },
        <String, dynamic>{
          'scenario': 'short_refresh_preserve',
          'probe': <String, dynamic>{
            'currentRoute': '/feed',
            'previousRoute': '/short',
          },
          'artifactStatus': <String, dynamic>{
            'exported': false,
            'reason': 'package_not_installed',
          },
          'telemetry': <String, dynamic>{
            'thresholdReport': <String, dynamic>{
              'issues': const <Map<String, dynamic>>[],
            },
          },
          'invariants': <String, dynamic>{'count': 0},
          'deviceLog': <String, dynamic>{
            'summary': <String, dynamic>{
              'issueCount': 1,
              'blockingCount': 0,
            },
          },
        },
      ],
    );

    expect(report.scenarioCount, 2);
    expect(report.failureCount, 1);
    expect(report.screenshotCount, 1);
    expect(report.invariantViolationCount, 1);
    expect(report.telemetryIssueCount, 2);
    expect(report.telemetryBlockingCount, 1);
    expect(report.deviceLogIssueCount, 3);
    expect(report.deviceLogBlockingCount, 1);
    expect(report.blockingScenarioCount, 1);
    expect(report.hasBlockingSignals, isTrue);
    expect(report.scenarios.first.artifactExported, isTrue);
    expect(report.scenarios.first.artifactReason, isEmpty);
    expect(report.scenarios.first.deviceLogIssueCount, 2);
    expect(report.scenarios.first.deviceLogBlockingCount, 1);
    expect(report.scenarios.last.artifactExported, isFalse);
    expect(report.scenarios.last.artifactReason, 'package_not_installed');
    expect(report.scenarios.last.deviceLogIssueCount, 1);
    expect(report.scenarios.last.deviceLogBlockingCount, 0);
  });

  test('dedupes alias artifacts by scenario and keeps strongest signals', () {
    final report = IntegrationSmokeReporter.buildReport(
      <Map<String, dynamic>>[
        <String, dynamic>{
          'scenario': 'feed_first_video_playback',
          'probe': <String, dynamic>{
            'currentRoute': '/NavBarView',
            'previousRoute': '/SignIn',
          },
          'artifactStatus': <String, dynamic>{
            'exported': true,
            'reason': '',
          },
          'telemetry': <String, dynamic>{
            'thresholdReport': <String, dynamic>{
              'issues': const <Map<String, dynamic>>[],
            },
          },
          'invariants': <String, dynamic>{'count': 0},
        },
        <String, dynamic>{
          'scenario': 'feed_first_video_playback',
          'probe': <String, dynamic>{
            'currentRoute': '/NavBarView',
            'previousRoute': '/SignIn',
          },
          'artifactStatus': <String, dynamic>{
            'exported': true,
            'reason': '',
          },
          'telemetry': <String, dynamic>{
            'thresholdReport': <String, dynamic>{
              'issues': const <Map<String, dynamic>>[],
            },
          },
          'invariants': <String, dynamic>{'count': 0},
          'deviceLog': <String, dynamic>{
            'summary': <String, dynamic>{
              'issueCount': 7,
              'blockingCount': 1,
            },
          },
        },
      ],
    );

    expect(report.scenarioCount, 1);
    expect(report.deviceLogIssueCount, 7);
    expect(report.deviceLogBlockingCount, 1);
    expect(report.blockingScenarioCount, 1);
    expect(report.scenarios.single.scenario, 'feed_first_video_playback');
    expect(report.scenarios.single.deviceLogIssueCount, 7);
    expect(report.scenarios.single.deviceLogBlockingCount, 1);
  });
}
