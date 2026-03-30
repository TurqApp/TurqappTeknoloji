import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turqappv2/Core/Services/global_video_adapter_pool.dart';
import 'package:turqappv2/Core/Services/integration_test_keys.dart';
import 'package:turqappv2/Core/Services/network_awareness_service.dart';
import 'package:turqappv2/Models/posts_model.dart';
import 'package:turqappv2/Modules/Agenda/agenda_controller.dart';
import 'package:turqappv2/hls_player/hls_video_adapter.dart';

import '../core/helpers/smoke_artifact_collector.dart';
import '../core/bootstrap/test_app_bootstrap.dart';

void main() {
  ensureIntegrationBinding();

  testWidgets(
    'Feed survives cellular-low and offline-cache network modes',
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
          'feed_network_resilience_smoke',
          tester,
          () async {
            await launchTurqApp(tester);
            await expectFeedScreen(tester);

            final network = NetworkAwarenessService.ensure();
            final controller = ensureAgendaController();

            final baseline = await _captureCurrentFeedVideo(
              tester,
              controller: controller,
            );
            expect(baseline, isNotNull);

            network.debugSetNetworkOverride(NetworkType.cellular);
            await tester.pump(const Duration(milliseconds: 600));
            await expectNoFlutterException(tester);

            final cellularSample = await _captureCurrentFeedVideo(
              tester,
              controller: controller,
            );
            expect(cellularSample, isNotNull);
            final cellularAdapter = await _waitForFeedAdapter(
              tester,
              sample: cellularSample!,
              label: 'cellular feed video',
            );
            await _waitForPlaybackAdvance(
              tester,
              adapter: cellularAdapter,
              minimumAdvance: const Duration(seconds: 1),
              label: 'cellular feed video',
            );

            network.debugSetNetworkOverride(NetworkType.none);
            await tester.pump(const Duration(milliseconds: 800));
            await expectNoFlutterException(tester);
            expect(byItKey(IntegrationTestKeys.screenFeed), findsOneWidget);
            expect(controller.agendaList.isNotEmpty, isTrue);

            await tester.drag(
              byItKey(IntegrationTestKeys.screenFeed),
              const Offset(0, -440),
            );
            for (var i = 0; i < 8; i++) {
              await tester.pump(const Duration(milliseconds: 180));
            }
            await expectNoFlutterException(tester);
            expect(byItKey(IntegrationTestKeys.screenFeed), findsOneWidget);
            expect(controller.agendaList.isNotEmpty, isTrue);

            network.debugSetNetworkOverride(null);
          },
        );
      } finally {
        NetworkAwarenessService.maybeFind()?.debugSetNetworkOverride(null);
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

Future<void> _waitForPlaybackAdvance(
  WidgetTester tester, {
  required HLSVideoAdapter adapter,
  required Duration minimumAdvance,
  required String label,
}) async {
  const timeout = Duration(seconds: 8);
  const step = Duration(milliseconds: 200);
  final maxTicks = timeout.inMilliseconds ~/ step.inMilliseconds;

  Duration? baseline;
  for (var i = 0; i < maxTicks; i++) {
    await tester.pump(step);
    final value = adapter.value;
    if (!value.isInitialized || adapter.isDisposed) continue;
    final position = value.position;
    if (baseline == null) {
      if (position > Duration.zero) {
        baseline = position;
      }
      continue;
    }
    final duration = value.duration;
    final remaining =
        duration > Duration.zero ? duration - baseline : Duration.zero;
    final targetAdvance = remaining < minimumAdvance &&
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
    if (!value.isPlaying &&
        !value.isBuffering &&
        position == baseline &&
        i > 4) {
      await adapter.recoverFrozenPlayback();
      await tester.pump(const Duration(milliseconds: 320));
    }
  }

  throw TestFailure(
    '$label did not advance playback '
    '(playing=${adapter.value.isPlaying}, position=${adapter.value.position}, '
    'duration=${adapter.value.duration}).',
  );
}
