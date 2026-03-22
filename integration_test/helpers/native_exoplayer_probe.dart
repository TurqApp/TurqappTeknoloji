import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turqappv2/hls_player/hls_controller.dart';

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
  Map<String, dynamic> last = const <String, dynamic>{};

  for (var i = 0; i < maxTicks; i++) {
    await tester.pump(step);
    last = await readNativeExoSmokeSnapshot();
    final active = last['active'] == true;
    if (!active) return;

    final runtime = readNativeExoRuntimeSnapshot(last);
    final isPlayingRuntime = runtime['isPlayingRuntime'] == true;
    final playerVolume = (runtime['playerVolume'] as num?)?.toDouble() ?? 0.0;
    final isMuted = runtime['isMuted'] == true;
    final playWhenReady = runtime['playWhenReady'] == true;

    final isAudiblePlayback =
        (isPlayingRuntime || playWhenReady) && playerVolume > 0.01 && !isMuted;
    if (!isAudiblePlayback) {
      return;
    }
  }

  throw TestFailure(
    '$label still has audible native feed playback '
    '(snapshot=${jsonEncode(last)}).',
  );
}
