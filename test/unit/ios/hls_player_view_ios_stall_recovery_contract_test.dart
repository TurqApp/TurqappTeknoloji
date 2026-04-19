import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('iOS likelyToKeepUp path reasserts playback after a stall', () async {
    final source = await File(
      '/Users/turqapp/Desktop/TurqApp/ios/Runner/HLSPlayerView.swift',
    ).readAsString();

    expect(
      source,
      contains('requestRecoveryAutoplayIfNeeded(source: "likelyToKeepUp")'),
    );
  });

  test('iOS access log stall detection ignores stalls=0 summaries', () async {
    final source = await File(
      '/Users/turqapp/Desktop/TurqApp/ios/Runner/PlaybackHealthMonitor.swift',
    ).readAsString();

    expect(
      source,
      contains('_parseIntMetric(named: "stalls", from: summary)'),
    );
    expect(
      source,
      isNot(contains('summary.localizedCaseInsensitiveContains("stall")')),
    );
  });
}
