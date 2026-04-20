import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turqappv2/Core/Services/integration_test_keys.dart';
import 'package:turqappv2/Modules/Short/short_controller.dart';
import 'package:turqappv2/hls_player/hls_video_adapter.dart';

import '../core/bootstrap/test_app_bootstrap.dart';
import '../core/helpers/smoke_artifact_collector.dart';

void main() {
  ensureIntegrationBinding();

  testWidgets(
    'Short auto-advances after the active video completes',
    (tester) async {
      await SmokeArtifactCollector.runScenario(
        'short_auto_advance_completion',
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
          final firstAdapter = await _waitForPlayableFrame(
            tester,
            controller: controller,
            index: 0,
            label: 'first short',
          );
          final duration = await _waitForKnownDuration(
            tester,
            adapter: firstAdapter,
            label: 'first short',
          );
          final seekTarget = duration > const Duration(milliseconds: 240)
              ? duration - const Duration(milliseconds: 120)
              : duration;
          await firstAdapter.seekTo(seekTarget);
          await tester.pump(const Duration(milliseconds: 180));

          await _waitForAutoAdvance(
            tester,
            controller: controller,
            expectedIndex: 1,
          );
          await _waitForPlayableFrame(
            tester,
            controller: controller,
            index: 1,
            label: 'second short after auto-advance',
          );
        },
      );
    },
    skip: !kRunIntegrationSmoke,
  );
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

Future<Duration> _waitForKnownDuration(
  WidgetTester tester, {
  required HLSVideoAdapter adapter,
  required String label,
}) async {
  const timeout = Duration(seconds: 4);
  const step = Duration(milliseconds: 120);
  final maxTicks = timeout.inMilliseconds ~/ step.inMilliseconds;
  for (var i = 0; i < maxTicks; i++) {
    await tester.pump(step);
    final duration = adapter.value.duration;
    if (duration > Duration.zero) {
      return duration;
    }
  }
  throw TestFailure('$label never exposed a known duration.');
}

Future<void> _waitForAutoAdvance(
  WidgetTester tester, {
  required ShortController controller,
  required int expectedIndex,
}) async {
  const timeout = Duration(seconds: 6);
  const step = Duration(milliseconds: 180);
  final maxTicks = timeout.inMilliseconds ~/ step.inMilliseconds;

  for (var i = 0; i < maxTicks; i++) {
    await tester.pump(step);
    if (controller.lastIndex.value == expectedIndex) {
      return;
    }
  }

  throw TestFailure(
    'Short auto-advance did not reach index $expectedIndex '
    '(current=${controller.lastIndex.value}, platform=$defaultTargetPlatform).',
  );
}
