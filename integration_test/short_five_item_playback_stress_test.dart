import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turqappv2/Core/Services/integration_test_keys.dart';
import 'package:turqappv2/Modules/Short/short_controller.dart';
import 'package:turqappv2/hls_player/hls_video_adapter.dart';

import 'helpers/smoke_artifact_collector.dart';
import 'helpers/test_app_bootstrap.dart';

void main() {
  ensureIntegrationBinding();

  testWidgets(
    'Short five items survive playback stress on device',
    (tester) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        final text = details.exceptionAsString();
        if (text.contains('cloud_firestore/permission-denied')) {
          debugPrint('Suppressed non-fatal: $text');
          return;
        }
        originalOnError?.call(details);
      };

      try {
        await SmokeArtifactCollector.runScenario(
          'short_five_item_playback_stress',
          tester,
          () async {
            await launchTurqApp(tester);
            await tapItKey(
              tester,
              IntegrationTestKeys.navShort,
              settlePumps: 12,
            );
            expect(byItKey(IntegrationTestKeys.screenShort), findsOneWidget);

            final controller = ShortController.ensure();

            await _assertPlayableForDuration(
              tester,
              controller: controller,
              index: 0,
              holdFor: _holdForIndex(controller, 0),
              label: 'short 0 initial',
            );
            await _exercisePausePlayMute(
              tester,
              controller: controller,
              index: 0,
              label: 'short 0 controls',
            );

            for (var index = 1; index < 5; index++) {
              await _swipeToNext(tester);
              await _assertPlayableForDuration(
                tester,
                controller: controller,
                index: index,
                holdFor: _holdForIndex(controller, index),
                label: 'short $index forward',
              );
              await _exercisePausePlayMute(
                tester,
                controller: controller,
                index: index,
                label: 'short $index controls',
              );
            }

            for (var index = 3; index >= 0; index--) {
              await _swipeToPrevious(tester);
              await _assertPlayableForDuration(
                tester,
                controller: controller,
                index: index,
                holdFor: _holdForIndex(controller, index),
                label: 'short $index backward',
              );
            }
          },
        );
      } finally {
        FlutterError.onError = originalOnError;
      }
    },
    skip: !kRunIntegrationSmoke,
  );
}

Future<void> _swipeToNext(WidgetTester tester) async {
  await tester.drag(
    byItKey(IntegrationTestKeys.screenShort),
    const Offset(0, -420),
  );
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 180));
  }
  await expectNoFlutterException(tester);
}

Future<void> _swipeToPrevious(WidgetTester tester) async {
  await tester.drag(
    byItKey(IntegrationTestKeys.screenShort),
    const Offset(0, 420),
  );
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 180));
  }
  await expectNoFlutterException(tester);
}

Future<void> _waitForPlayableFrame(
  WidgetTester tester, {
  required ShortController controller,
  required int index,
  required String label,
}) async {
  const timeout = Duration(seconds: 8);
  const step = Duration(milliseconds: 200);
  final maxTicks = timeout.inMilliseconds ~/ step.inMilliseconds;

  for (var i = 0; i < maxTicks; i++) {
    await tester.pump(step);
    final adapter = controller.cache[index];
    final value = adapter?.value;
    final playable = adapter != null &&
        !adapter.isDisposed &&
        value != null &&
        value.isInitialized &&
        value.hasRenderedFirstFrame &&
        (value.isPlaying || value.position > Duration.zero);
    if (playable) {
      _logState(label, index, value);
      return;
    }
  }

  final adapter = controller.cache[index];
  final value = adapter?.value;
  throw TestFailure(
    '$label did not reach playable frame state '
    '(exists=${adapter != null}, disposed=${adapter?.isDisposed}, '
    'initialized=${value?.isInitialized}, firstFrame=${value?.hasRenderedFirstFrame}, '
    'playing=${value?.isPlaying}, position=${value?.position}).',
  );
}

Future<void> _waitForPlaybackAdvance(
  WidgetTester tester, {
  required ShortController controller,
  required int index,
  required Duration minimumAdvance,
  required String label,
}) async {
  const timeout = Duration(seconds: 12);
  const step = Duration(milliseconds: 200);
  final maxTicks = timeout.inMilliseconds ~/ step.inMilliseconds;

  Duration? baseline;
  for (var i = 0; i < maxTicks; i++) {
    await tester.pump(step);
    final adapter = controller.cache[index];
    final value = adapter?.value;
    if (adapter == null || adapter.isDisposed || value == null) {
      continue;
    }
    final position = value.position;
    if (baseline == null) {
      if (position > Duration.zero) {
        baseline = position;
      }
      continue;
    }
    final duration = value.duration;
    final remaining = duration > Duration.zero ? duration - baseline : null;
    final targetAdvance = remaining != null &&
            remaining < minimumAdvance &&
            remaining > const Duration(milliseconds: 400)
        ? remaining - const Duration(milliseconds: 250)
        : minimumAdvance;

    if (position - baseline >= targetAdvance) {
      _logState('$label advanced', index, value);
      return;
    }

    final nearEnd = duration > Duration.zero &&
        position >= duration - const Duration(milliseconds: 250);
    if (value.isCompleted || nearEnd) {
      _logState('$label completed-near-end', index, value);
      return;
    }
  }

  final adapter = controller.cache[index];
  final value = adapter?.value;
  throw TestFailure(
    '$label did not advance playback by ${minimumAdvance.inSeconds}s '
    '(exists=${adapter != null}, disposed=${adapter?.isDisposed}, '
    'playing=${value?.isPlaying}, position=${value?.position}).',
  );
}

Future<void> _waitForPaused(
  WidgetTester tester, {
  required HLSVideoAdapter adapter,
  required String label,
}) async {
  const timeout = Duration(seconds: 4);
  const step = Duration(milliseconds: 150);
  final maxTicks = timeout.inMilliseconds ~/ step.inMilliseconds;
  for (var i = 0; i < maxTicks; i++) {
    await tester.pump(step);
    if (!adapter.value.isPlaying) {
      _logState(label, -1, adapter.value);
      return;
    }
  }
  throw TestFailure('$label did not enter paused state.');
}

Future<void> _exercisePausePlayMute(
  WidgetTester tester, {
  required ShortController controller,
  required int index,
  required String label,
}) async {
  final adapter = controller.cache[index];
  if (adapter == null || adapter.isDisposed) {
    throw TestFailure('$label adapter missing for index $index');
  }

  if (_shouldSkipControls(adapter.value)) {
    _logState('$label controls-skipped-short-duration', index, adapter.value);
    return;
  }

  await adapter.pause();
  await _waitForPaused(
    tester,
    adapter: adapter,
    label: '$label pause',
  );

  await adapter.play();
  await _waitForPlayableFrame(
    tester,
    controller: controller,
    index: index,
    label: '$label resume',
  );

  await adapter.setVolume(0);
  _logState('$label mute', index, adapter.value, extra: 'volume=0');
  await _waitForPlaybackAdvance(
    tester,
    controller: controller,
    index: index,
    minimumAdvance: const Duration(seconds: 1),
    label: '$label muted playback',
  );

  await adapter.setVolume(1);
  _logState('$label unmute', index, adapter.value, extra: 'volume=1');
  await _waitForPlaybackAdvance(
    tester,
    controller: controller,
    index: index,
    minimumAdvance: const Duration(seconds: 1),
    label: '$label unmuted playback',
  );
}

Future<void> _assertPlayableForDuration(
  WidgetTester tester, {
  required ShortController controller,
  required int index,
  required Duration holdFor,
  required String label,
}) async {
  await _waitForPlayableFrame(
    tester,
    controller: controller,
    index: index,
    label: label,
  );
  await _waitForPlaybackAdvance(
    tester,
    controller: controller,
    index: index,
    minimumAdvance: holdFor,
    label: label,
  );
}

Duration _holdForIndex(ShortController controller, int index) {
  final value = controller.cache[index]?.value;
  final duration = value?.duration ?? Duration.zero;
  if (duration <= Duration.zero) return const Duration(seconds: 5);
  if (duration <= const Duration(seconds: 6)) {
    return const Duration(milliseconds: 1800);
  }
  if (duration <= const Duration(seconds: 8)) {
    return const Duration(seconds: 2);
  }
  if (duration <= const Duration(seconds: 12)) {
    return const Duration(seconds: 3);
  }
  return const Duration(seconds: 5);
}

bool _shouldSkipControls(HLSVideoValue value) {
  final duration = value.duration;
  if (duration <= Duration.zero) return false;
  final remaining = duration - value.position;
  return remaining <= const Duration(seconds: 2);
}

void _logState(
  String label,
  int index,
  HLSVideoValue value, {
  String extra = '',
}) {
  debugPrint(
    '[short-stress] $label index=$index '
    'init=${value.isInitialized} '
    'firstFrame=${value.hasRenderedFirstFrame} '
    'playing=${value.isPlaying} '
    'buffering=${value.isBuffering} '
    'completed=${value.isCompleted} '
    'position=${value.position} '
    'duration=${value.duration} '
    '${extra.isEmpty ? '' : extra}',
  );
}
