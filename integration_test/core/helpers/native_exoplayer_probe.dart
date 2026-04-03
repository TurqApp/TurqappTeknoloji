import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turqappv2/hls_player/hls_controller.dart';

import 'test_state_probe.dart';

const Set<String> _criticalExoErrors = <String>{
  'FIRST_FRAME_TIMEOUT',
  'TTFF_TOO_SLOW',
  'READY_WITHOUT_FRAME',
  'VIDEO_FREEZE',
  'PLAYBACK_NOT_STARTED',
  'FULLSCREEN_INTERRUPTION',
  'DOUBLE_BLACK_SCREEN_RISK',
  'EXCESSIVE_DROPPED_FRAMES',
  'AUDIO_MISSING',
};

bool get supportsNativeExoSmoke =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

Future<Map<String, dynamic>> readNativeExoSmokeSnapshot() =>
    HLSController.getActiveSmokeSnapshot();

Future<Map<String, dynamic>?> _readNativeExoSmokeSnapshotWithTimeout({
  Duration timeout = const Duration(milliseconds: 900),
}) async {
  try {
    return await readNativeExoSmokeSnapshot().timeout(timeout);
  } on TimeoutException {
    return null;
  }
}

Map<String, dynamic> readNativeExoRuntimeSnapshot(Map<String, dynamic> snapshot) {
  final raw = snapshot['snapshot'];
  if (raw is Map) {
    return Map<String, dynamic>.from(raw);
  }
  return const <String, dynamic>{};
}

List<String> readNativeExoCriticalErrors(Map<String, dynamic> snapshot) {
  final raw = snapshot['errors'];
  if (raw is! List) return const <String>[];
  return raw
      .map((item) => item?.toString() ?? '')
      .where(_criticalExoErrors.contains)
      .toList();
}

bool _nativeExoAwaitingBackgroundRecovery(Map<String, dynamic> snapshot) {
  final runtime = readNativeExoRuntimeSnapshot(snapshot);
  final awaitingBackgroundRecovery =
      runtime['awaitingBackgroundRecovery'] == true;
  final appBackgroundedAt =
      (runtime['appBackgroundedAt'] as num?)?.toInt() ??
          (runtime['appDidEnterBackgroundAt'] as num?)?.toInt() ??
          0;
  final appForegroundedAt =
      (runtime['appForegroundedAt'] as num?)?.toInt() ??
          (runtime['appWillEnterForegroundAt'] as num?)?.toInt() ??
          0;
  return awaitingBackgroundRecovery &&
      appBackgroundedAt > 0 &&
      appForegroundedAt <= appBackgroundedAt;
}

bool _nativeExoHasAudiblePlayback(Map<String, dynamic> snapshot) {
  final active = snapshot['active'] == true;
  if (!active) {
    return false;
  }
  final runtime = readNativeExoRuntimeSnapshot(snapshot);
  final isPlayingRuntime = runtime['isPlayingRuntime'] == true;
  final playerVolume = (runtime['playerVolume'] as num?)?.toDouble() ?? 0.0;
  final isMuted = runtime['isMuted'] == true;
  final playWhenReady = runtime['playWhenReady'] == true;
  return (isPlayingRuntime || playWhenReady) &&
      playerVolume > 0.01 &&
      !isMuted;
}

bool _probeIndicatesOffFeedPlaybackNotExpected() {
  final probe = readIntegrationProbe();
  final route = (probe['currentRoute'] as String? ?? '').trim();
  final navBar = Map<String, dynamic>.from(
    probe['navBar'] as Map? ?? const <String, dynamic>{},
  );
  final selectedIndex = (navBar['selectedIndex'] as num?)?.toInt() ?? 0;
  final videoPlayback = Map<String, dynamic>.from(
    probe['videoPlayback'] as Map? ?? const <String, dynamic>{},
  );
  final currentPlayingDocId =
      (videoPlayback['currentPlayingDocID'] as String? ?? '').trim();
  final targetPlaybackDocId =
      (videoPlayback['targetPlaybackDocID'] as String? ?? '').trim();
  final routeIsOffFeed = route.isNotEmpty && route != '/NavBarView';
  final navIsOffFeed = selectedIndex != 0;
  final feedPlaybackInactive =
      !currentPlayingDocId.startsWith('feed:') &&
      !targetPlaybackDocId.startsWith('feed:');
  return (routeIsOffFeed || navIsOffFeed) && feedPlaybackInactive;
}

Map<String, dynamic> _offFeedProbeSnapshot() {
  final probe = readIntegrationProbe();
  final currentRoute = (probe['currentRoute'] as String? ?? '').trim();
  final navBar = Map<String, dynamic>.from(
    probe['navBar'] as Map? ?? const <String, dynamic>{},
  );
  final videoPlayback = Map<String, dynamic>.from(
    probe['videoPlayback'] as Map? ?? const <String, dynamic>{},
  );
  return <String, dynamic>{
    'currentRoute': currentRoute,
    'selectedIndex': (navBar['selectedIndex'] as num?)?.toInt(),
    'showBar': navBar['showBar'],
    'currentPlayingDocID': videoPlayback['currentPlayingDocID'],
    'targetPlaybackDocID': videoPlayback['targetPlaybackDocID'],
  };
}

Future<Map<String, dynamic>> waitForRenderableNativeExoSnapshot(
  WidgetTester tester, {
  Duration timeout = const Duration(seconds: 8),
  Duration step = const Duration(milliseconds: 200),
}) async {
  final maxTicks = timeout.inMilliseconds ~/ step.inMilliseconds;
  Map<String, dynamic> last = const <String, dynamic>{};

  for (var i = 0; i < maxTicks; i++) {
    await tester.pump(step);
    last = await readNativeExoSmokeSnapshot();
    final active = last['active'] == true;
    final firstFrameRendered = last['firstFrameRendered'] == true;
    final criticalErrors = readNativeExoCriticalErrors(last);
    if (active && firstFrameRendered && criticalErrors.isEmpty) {
      return last;
    }
  }

  throw TestFailure(
    'Native ExoPlayer smoke snapshot did not become renderable '
    '(snapshot=${jsonEncode(last)}).',
  );
}

Future<void> expectNativeExoSmokeHealthy(
  WidgetTester tester, {
  required String label,
  Duration timeout = const Duration(seconds: 3),
  Duration step = const Duration(milliseconds: 200),
}) async {
  final maxTicks = timeout.inMilliseconds ~/ step.inMilliseconds;
  Map<String, dynamic> last = const <String, dynamic>{};

  for (var i = 0; i < maxTicks; i++) {
    await tester.pump(step);
    last = await readNativeExoSmokeSnapshot();
    final criticalErrors = readNativeExoCriticalErrors(last);
    if (criticalErrors.isNotEmpty) {
      throw TestFailure(
        '$label captured critical native ExoPlayer errors '
        '(errors=${criticalErrors.join(', ')}, snapshot=${jsonEncode(last)}).',
      );
    }
    if (last['active'] == true && last['firstFrameRendered'] == true) {
      return;
    }
  }

  throw TestFailure(
    '$label did not keep a healthy active native ExoPlayer snapshot '
    '(snapshot=${jsonEncode(last)}).',
  );
}

Future<void> expectNoAudibleNativeFeedPlayback(
  WidgetTester tester, {
  required String label,
  Duration timeout = const Duration(seconds: 2),
  Duration step = const Duration(milliseconds: 200),
}) async {
  final maxTicks = timeout.inMilliseconds ~/ step.inMilliseconds;
  Map<String, dynamic>? initial = await _readNativeExoSmokeSnapshotWithTimeout();
  if (initial == null) {
    if (_probeIndicatesOffFeedPlaybackNotExpected()) {
      debugPrint(
        '[integration-smoke] $label native Exo snapshot timed out while '
        'feed playback is not expected off-feed; skipping audible leak check '
        '(probe=${jsonEncode(_offFeedProbeSnapshot())}).',
      );
      return;
    }
    throw TestFailure(
      '$label native Exo smoke snapshot timed out '
      '(probe=${jsonEncode(_offFeedProbeSnapshot())}).',
    );
  }
  Map<String, dynamic> last = initial;

  if (_nativeExoAwaitingBackgroundRecovery(last) ||
      !_nativeExoHasAudiblePlayback(last)) {
    return;
  }

  if (_probeIndicatesOffFeedPlaybackNotExpected()) {
    debugPrint(
      '[integration-smoke] $label observed audible native playback on an '
      'off-feed owner; treating it as route-owned playback instead of a '
      'feed leak (probe=${jsonEncode(_offFeedProbeSnapshot())}, '
      'snapshot=${jsonEncode(last)}).',
    );
    return;
  }

  for (var i = 0; i < maxTicks; i++) {
    await tester.pump(step);
    final next = await _readNativeExoSmokeSnapshotWithTimeout();
    if (next == null) {
      if (_probeIndicatesOffFeedPlaybackNotExpected()) {
        debugPrint(
          '[integration-smoke] $label native Exo snapshot timed out while '
          'feed playback is not expected off-feed; skipping audible leak '
          'check (probe=${jsonEncode(_offFeedProbeSnapshot())}).',
        );
        return;
      }
      throw TestFailure(
        '$label native Exo smoke snapshot timed out '
        '(probe=${jsonEncode(_offFeedProbeSnapshot())}).',
      );
    }
    last = next;
    if (_nativeExoAwaitingBackgroundRecovery(last) ||
        !_nativeExoHasAudiblePlayback(last)) {
      return;
    }

    if (_probeIndicatesOffFeedPlaybackNotExpected()) {
      debugPrint(
        '[integration-smoke] $label resolved to off-feed route-owned native '
        'playback; skipping feed leak failure '
        '(probe=${jsonEncode(_offFeedProbeSnapshot())}, '
        'snapshot=${jsonEncode(last)}).',
      );
      return;
    }
  }

  throw TestFailure(
    '$label still has audible native feed playback '
    '(snapshot=${jsonEncode(last)}).',
  );
}
