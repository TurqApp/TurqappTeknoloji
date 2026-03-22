import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turqappv2/Core/Services/integration_test_keys.dart';
import 'package:turqappv2/Modules/Agenda/agenda_controller.dart';

import '../core/helpers/native_exoplayer_probe.dart';
import '../core/helpers/smoke_artifact_collector.dart';
import '../core/bootstrap/test_app_bootstrap.dart';

void main() {
  ensureIntegrationBinding();

  testWidgets(
    'Feed native ExoPlayer truth stays healthy across first playback and scroll',
    (tester) async {
      if (!supportsNativeExoSmoke) {
        return;
      }

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
          'feed_native_exoplayer_truth_smoke',
          tester,
          () async {
            await launchTurqApp(tester);
            await expectFeedScreen(tester);

            final controller = AgendaController.ensure();
            await _waitForCenteredPlayableFeedItem(
              tester,
              controller: controller,
            );

            await waitForRenderableNativeExoSnapshot(tester);
            await expectNativeExoSmokeHealthy(
              tester,
              label: 'feed first video',
            );

            for (var i = 0; i < 5; i++) {
              await tester.drag(
                byItKey(IntegrationTestKeys.screenFeed),
                const Offset(0, -420),
              );
              for (var j = 0; j < 8; j++) {
                await tester.pump(const Duration(milliseconds: 180));
              }
              await expectNoFlutterException(tester);

              await _waitForCenteredPlayableFeedItem(
                tester,
                controller: controller,
              );
              await waitForRenderableNativeExoSnapshot(tester);
              await expectNativeExoSmokeHealthy(
                tester,
                label: 'feed scroll step ${i + 1}',
              );
            }
          },
        );
      } finally {
        FlutterError.onError = originalOnError;
      }
    },
    skip: !kRunIntegrationSmoke ||
        defaultTargetPlatform != TargetPlatform.android,
  );
}

Future<void> _waitForCenteredPlayableFeedItem(
  WidgetTester tester, {
  required AgendaController controller,
}) async {
  const timeout = Duration(seconds: 8);
  const step = Duration(milliseconds: 200);
  final maxTicks = timeout.inMilliseconds ~/ step.inMilliseconds;

  for (var i = 0; i < maxTicks; i++) {
    await tester.pump(step);
    final centered = controller.centeredIndex.value;
    if (centered < 0 || centered >= controller.agendaList.length) {
      continue;
    }
    final post = controller.agendaList[centered];
    if (controller.canAutoplayInTests(post) && post.docID.trim().isNotEmpty) {
      return;
    }
  }

  throw TestFailure('Feed did not settle on a centered autoplayable video.');
}
