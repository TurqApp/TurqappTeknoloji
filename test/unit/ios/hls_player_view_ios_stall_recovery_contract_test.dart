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

  test('iOS play event only emits on real timeControlStatus transitions',
      () async {
    final source = await File(
      '/Users/turqapp/Desktop/TurqApp/ios/Runner/HLSPlayerView.swift',
    ).readAsString();

    expect(
      source,
      contains(
        'private var lastObservedTimeControlStatus: AVPlayer.TimeControlStatus?',
      ),
    );
    expect(
      source,
      contains('if self?.lastObservedTimeControlStatus == status {'),
    );
    expect(
      source,
      contains('self?.lastObservedTimeControlStatus = status'),
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

  test('iOS freeze guard only flags active playback windows', () async {
    final source = await File(
      '/Users/turqapp/Desktop/TurqApp/ios/Runner/PlaybackHealthMonitor.swift',
    ).readAsString();

    expect(source, contains('private func isInActivePlaybackWindow('));
    expect(
      source,
      contains(
        'return (isPlaying && !isBuffering) ||\n'
        '            recentPlaybackProgress',
      ),
    );
    expect(
      source,
      contains('guard isInActivePlaybackWindow('),
    );
  });

  test('iOS freeze guard does not classify buffering startup as video freeze',
      () async {
    final source = await File(
      '/Users/turqapp/Desktop/TurqApp/ios/Runner/PlaybackHealthMonitor.swift',
    ).readAsString();

    expect(
      source,
      isNot(
        contains('(isPlaybackExpected && isBuffering)'),
      ),
    );
    expect(
      source,
      contains('(isPlaying && !isBuffering) ||'),
    );
  });

  test('iOS freeze guard clears recent-progress window on pause', () async {
    final source = await File(
      '/Users/turqapp/Desktop/TurqApp/ios/Runner/PlaybackHealthMonitor.swift',
    ).readAsString();

    expect(
      source,
      contains('func onPlaybackPaused() {'),
    );
    expect(
      source,
      contains('isPlaybackExpected = false'),
    );
    expect(
      source,
      contains('lastPlaybackProgressedAt = 0'),
    );
  });
}
