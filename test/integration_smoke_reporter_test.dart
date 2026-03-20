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
          'invariants': <String, dynamic>{'count': 1},
          'failure': <String, dynamic>{'screenshotPath': 'x.png'},
        },
        <String, dynamic>{
          'scenario': 'short_refresh_preserve',
          'probe': <String, dynamic>{
            'currentRoute': '/feed',
            'previousRoute': '/short',
          },
          'telemetry': <String, dynamic>{
            'thresholdReport': <String, dynamic>{
              'issues': const <Map<String, dynamic>>[],
            },
          },
          'invariants': <String, dynamic>{'count': 0},
        },
      ],
    );

    expect(report.scenarioCount, 2);
    expect(report.failureCount, 1);
    expect(report.screenshotCount, 1);
    expect(report.invariantViolationCount, 1);
    expect(report.telemetryIssueCount, 2);
    expect(report.telemetryBlockingCount, 1);
    expect(report.blockingScenarioCount, 1);
    expect(report.hasBlockingSignals, isTrue);
  });
}
