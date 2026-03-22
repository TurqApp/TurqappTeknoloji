import 'package:flutter_test/flutter_test.dart';
import 'package:turqappv2/Core/Services/integration_test_keys.dart';
import 'package:turqappv2/Modules/Short/short_controller.dart';

import '../core/helpers/smoke_artifact_collector.dart';
import '../core/bootstrap/test_app_bootstrap.dart';

void main() {
  ensureIntegrationBinding();

  testWidgets(
    'Short first two items render playable video on device',
    (tester) async {
      await SmokeArtifactCollector.runScenario(
        'short_first_two_playback',
        tester,
        () async {
          await launchTurqApp(tester);
          await tapItKey(tester, IntegrationTestKeys.navShort, settlePumps: 12);
          expect(byItKey(IntegrationTestKeys.screenShort), findsOneWidget);

          final controller = ShortController.ensure();
          for (var cycle = 0; cycle < 3; cycle++) {
            await _assertPlayableForDuration(
              tester,
              controller: controller,
              index: 0,
              holdFor: const Duration(seconds: 5),
              label: 'first short cycle ${cycle + 1}',
            );

            await tester.drag(
              byItKey(IntegrationTestKeys.screenShort),
              const Offset(0, -420),
            );
            for (var i = 0; i < 12; i++) {
              await tester.pump(const Duration(milliseconds: 180));
            }
            await expectNoFlutterException(tester);

            await _assertPlayableForDuration(
              tester,
              controller: controller,
              index: 1,
              holdFor: const Duration(seconds: 5),
              label: 'second short cycle ${cycle + 1}',
            );

            await tester.drag(
              byItKey(IntegrationTestKeys.screenShort),
              const Offset(0, 420),
            );
            for (var i = 0; i < 12; i++) {
              await tester.pump(const Duration(milliseconds: 180));
            }
            await expectNoFlutterException(tester);
          }
        },
      );
    },
    skip: !kRunIntegrationSmoke,
  );
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
    final error = tester.takeException();
    if (error != null) {
      throw TestFailure('$label exception: $error');
    }

    final adapter = controller.cache[index];
    final value = adapter?.value;
    final playable = adapter != null &&
        !adapter.isDisposed &&
        value != null &&
        value.isInitialized &&
        value.hasRenderedFirstFrame &&
        (value.isPlaying || value.position > Duration.zero);
    if (playable) {
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
  const timeout = Duration(seconds: 10);
  const step = Duration(milliseconds: 200);
  final maxTicks = timeout.inMilliseconds ~/ step.inMilliseconds;

  Duration? baseline;
  for (var i = 0; i < maxTicks; i++) {
    await tester.pump(step);
    final error = tester.takeException();
    if (error != null) {
      throw TestFailure('$label exception while waiting advance: $error');
    }

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
    if (position - baseline >= minimumAdvance) {
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
