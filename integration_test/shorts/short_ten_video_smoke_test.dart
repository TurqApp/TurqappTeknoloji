import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turqappv2/Core/Services/integration_test_keys.dart';
import 'package:turqappv2/Modules/Short/short_controller.dart';
import 'package:turqappv2/hls_player/hls_video_adapter.dart';

import '../core/helpers/smoke_artifact_collector.dart';
import '../core/bootstrap/test_app_bootstrap.dart';

void main() {
  ensureIntegrationBinding();

  testWidgets(
    'Short keeps first ten videos audible and advancing',
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
          'short_ten_video_smoke',
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
            final seenIndices = <int>{};

            for (var index = 0; index < 10; index++) {
              if (index > 0) {
                await _swipeToNext(tester);
              }
              await _assertShortHealthy(
                tester,
                controller: controller,
                index: index,
                label: 'short video ${index + 1}',
              );
              seenIndices.add(index);
            }

            expect(
              seenIndices.length,
              10,
              reason: 'Short smoke should validate 10 consecutive videos.',
            );
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

Future<void> _assertShortHealthy(
  WidgetTester tester, {
  required ShortController controller,
  required int index,
  required String label,
}) async {
  final adapter = await _waitForPlayableFrame(
    tester,
    controller: controller,
    index: index,
    label: label,
  );

  final initiallyMuted = await adapter.isMutedNative();
  if (initiallyMuted) {
    throw TestFailure('$label started muted (index=$index).');
  }

  await _waitForPlaybackAdvance(
    tester,
    controller: controller,
    index: index,
    minimumAdvance: _holdForIndex(controller, index),
    label: label,
  );

  final mutedAfterAdvance = await adapter.isMutedNative();
  if (mutedAfterAdvance) {
    throw TestFailure('$label became muted after advance (index=$index).');
  }
}

Future<HLSVideoAdapter> _waitForPlayableFrame(
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
      return adapter;
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
      return;
    }

    final nearEnd = duration > Duration.zero &&
        position >= duration - const Duration(milliseconds: 250);
    if (value.isCompleted || nearEnd) {
      return;
    }
  }

  final adapter = controller.cache[index];
  final value = adapter?.value;
  throw TestFailure(
    '$label did not advance playback '
    '(exists=${adapter != null}, disposed=${adapter?.isDisposed}, '
    'playing=${value?.isPlaying}, position=${value?.position}).',
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
