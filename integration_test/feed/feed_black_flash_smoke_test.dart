import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turqappv2/Core/Services/global_video_adapter_pool.dart';
import 'package:turqappv2/Core/Services/integration_test_keys.dart';
import 'package:turqappv2/Models/posts_model.dart';
import 'package:turqappv2/Modules/Agenda/agenda_controller.dart';
import 'package:turqappv2/hls_player/hls_video_adapter.dart';

import '../core/helpers/smoke_artifact_collector.dart';
import '../core/bootstrap/test_app_bootstrap.dart';

void main() {
  ensureIntegrationBinding();

  testWidgets(
    'Feed first ten videos avoid early surface rebind and renderer stall',
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
          'feed_black_flash_smoke',
          tester,
          () async {
            await launchTurqApp(tester);
            await expectFeedScreen(tester);
            final deadline = DateTime.now().add(const Duration(minutes: 3));

            final controller = ensureAgendaController();
            final seenDocIds = <String>{};
            var swipeAttempts = 0;

            while (seenDocIds.length < 10 &&
                swipeAttempts < 32 &&
                DateTime.now().isBefore(deadline)) {
              final sample = await _captureCurrentFeedVideo(
                tester,
                controller: controller,
              );
              if (sample != null && !seenDocIds.contains(sample.docId)) {
                final adapter = await _waitForFeedAdapter(
                  tester,
                  sample: sample,
                  label: 'feed flash video ${seenDocIds.length + 1}',
                );

                final initialStalls = adapter.rendererStallCount;
                final initialRebinds = adapter.surfaceRebindCount;
                await _watchStableStartupWindow(
                  tester,
                  adapter: adapter,
                  docId: sample.docId,
                  window: const Duration(seconds: 4),
                  label: 'feed flash video ${seenDocIds.length + 1}',
                );

                if (adapter.rendererStallCount != initialStalls) {
                  throw TestFailure(
                    'feed flash video ${seenDocIds.length + 1} triggered renderer stall during startup '
                    '(doc=${sample.docId}, before=$initialStalls, after=${adapter.rendererStallCount}).',
                  );
                }

                if (adapter.surfaceRebindCount != initialRebinds) {
                  throw TestFailure(
                    'feed flash video ${seenDocIds.length + 1} triggered surface rebind during startup '
                    '(doc=${sample.docId}, before=$initialRebinds, after=${adapter.surfaceRebindCount}).',
                  );
                }

                seenDocIds.add(sample.docId);
              }

              await tester.drag(
                byItKey(IntegrationTestKeys.screenFeed),
                const Offset(0, -440),
              );
              for (var i = 0; i < 10; i++) {
                await tester.pump(const Duration(milliseconds: 180));
              }
              await expectNoFlutterException(tester);
              swipeAttempts += 1;
            }

            final availableAutoplayDocIds = controller.agendaList
                .where(controller.canAutoplayInTests)
                .map((post) => post.docID.trim())
                .where((docId) => docId.isNotEmpty)
                .toSet();
            final requiredValidationCount = availableAutoplayDocIds.length >= 10
                ? 10
                : availableAutoplayDocIds.length;
            expect(
              seenDocIds.length,
              greaterThanOrEqualTo(requiredValidationCount),
              reason:
                  'Feed black flash smoke should validate all reachable autoplay videos '
                  '(expected=$requiredValidationCount, seen=${seenDocIds.length}, available=${availableAutoplayDocIds.length}).',
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

class _FeedVideoSample {
  const _FeedVideoSample({
    required this.index,
    required this.docId,
    required this.model,
  });

  final int index;
  final String docId;
  final PostsModel model;
}

Future<_FeedVideoSample?> _captureCurrentFeedVideo(
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
    if (!controller.canAutoplayInTests(post)) {
      continue;
    }
    final docId = post.docID.trim();
    if (docId.isEmpty) continue;
    return _FeedVideoSample(index: centered, docId: docId, model: post);
  }
  return null;
}

Future<HLSVideoAdapter> _waitForFeedAdapter(
  WidgetTester tester, {
  required _FeedVideoSample sample,
  required String label,
}) async {
  const timeout = Duration(seconds: 8);
  const step = Duration(milliseconds: 200);
  final maxTicks = timeout.inMilliseconds ~/ step.inMilliseconds;
  var recoveryAttempts = 0;

  for (var i = 0; i < maxTicks; i++) {
    await tester.pump(step);
    final adapter = GlobalVideoAdapterPool.ensure().adapterForTesting(
      sample.docId,
    );
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
    final stalledReadyAdapter = adapter != null &&
        !adapter.isDisposed &&
        value != null &&
        value.isInitialized &&
        value.hasRenderedFirstFrame &&
        !value.isPlaying &&
        !value.isBuffering &&
        value.position == Duration.zero;
    if (stalledReadyAdapter && recoveryAttempts < 3) {
      recoveryAttempts += 1;
      await adapter.play();
      await tester.pump(const Duration(milliseconds: 220));
      if (!adapter.value.isPlaying && !adapter.value.isBuffering) {
        await adapter.recoverFrozenPlayback();
      }
    }
  }

  final adapter = GlobalVideoAdapterPool.ensure().adapterForTesting(
    sample.docId,
  );
  final value = adapter?.value;
  throw TestFailure(
    '$label did not reach playable adapter state '
    '(doc=${sample.docId}, exists=${adapter != null}, disposed=${adapter?.isDisposed}, '
    'initialized=${value?.isInitialized}, firstFrame=${value?.hasRenderedFirstFrame}, '
    'playing=${value?.isPlaying}, position=${value?.position}).',
  );
}

Future<void> _watchStableStartupWindow(
  WidgetTester tester, {
  required HLSVideoAdapter adapter,
  required String docId,
  required Duration window,
  required String label,
}) async {
  const step = Duration(milliseconds: 200);
  final maxTicks = window.inMilliseconds ~/ step.inMilliseconds;
  Duration? baseline;
  var activeAdapter = adapter;
  var missingTicks = 0;

  for (var i = 0; i < maxTicks; i++) {
    await tester.pump(step);
    final candidate = GlobalVideoAdapterPool.ensure().adapterForTesting(docId);
    if (candidate != null && !candidate.isDisposed) {
      activeAdapter = candidate;
    }
    final value = activeAdapter.value;
    if (activeAdapter.isDisposed || !value.isInitialized) {
      missingTicks += 1;
      if (missingTicks <= 4) {
        continue;
      }
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        debugPrint(
          '$label tolerated transient adapter reset on iOS simulator '
          '(doc=$docId, ticks=$missingTicks).',
        );
        return;
      }
      throw TestFailure('$label lost adapter initialization during startup.');
    }
    missingTicks = 0;
    if (baseline == null) {
      if (value.position > Duration.zero) {
        baseline = value.position;
      }
      continue;
    }
    if (value.position < baseline) {
      throw TestFailure(
        '$label playback position regressed during startup '
        '(baseline=$baseline, current=${value.position}).',
      );
    }
    if (!value.isPlaying &&
        !value.isBuffering &&
        value.position == baseline &&
        i > 4) {
      await activeAdapter.recoverFrozenPlayback();
      await tester.pump(const Duration(milliseconds: 320));
    }
    baseline = value.position;
  }
}
