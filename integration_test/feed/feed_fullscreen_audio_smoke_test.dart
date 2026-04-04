import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Services/integration_test_keys.dart';
import 'package:turqappv2/Models/posts_model.dart';
import 'package:turqappv2/Modules/Agenda/agenda_controller.dart';
import 'package:turqappv2/Modules/Short/single_short_view.dart';
import 'package:turqappv2/hls_player/hls_video_adapter.dart';

import '../core/helpers/smoke_artifact_collector.dart';
import '../core/helpers/player_contract_helpers.dart';
import '../core/bootstrap/test_app_bootstrap.dart';

void main() {
  ensureIntegrationBinding();

  testWidgets(
    'Feed fullscreen keeps current video audible and advancing',
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
          'feed_fullscreen_audio_smoke',
          tester,
          () async {
            await launchTurqApp(
              tester,
              relaxFeedFixtureDocRequirement: true,
            );
            await expectFeedScreen(tester);

            final controller = ensureAgendaController();
            final sample = await _captureCurrentFeedVideo(
              tester,
              controller: controller,
            );
            expect(sample, isNotNull);

            final adapter = await _waitForFeedAdapter(
              tester,
              sample: sample!,
              label: 'feed fullscreen source',
            );

            final preMuted = await adapter.isMutedNative();
            if (preMuted) {
              final becameAudible = await _waitForAudibleOrUnmuted(adapter);
              if (!becameAudible) {
                throw TestFailure(
                  'feed fullscreen source stayed muted beyond grace window '
                  '(doc=${sample.docId}).',
                );
              }
            }

            Get.to(() => SingleShortView(
                  startModel: sample.model,
                  startList: [sample.model],
                  initialPosition: adapter.value.position,
                  injectedController: adapter,
                ));

            for (var i = 0; i < 12; i++) {
              await tester.pump(const Duration(milliseconds: 180));
            }
            await expectNoFlutterException(tester);
            expect(
              byItKey(IntegrationTestKeys.screenSingleShort),
              findsOneWidget,
            );

            final fullscreenMuted = await adapter.isMutedNative();
            if (fullscreenMuted) {
              final regainedAudibility =
                  await _waitForAudibleOrUnmuted(adapter);
              if (!regainedAudibility) {
                throw TestFailure(
                  'fullscreen route muted injected video '
                  '(doc=${sample.docId}).',
                );
              }
            }

            await _waitForPlaybackAdvance(
              tester,
              adapter: adapter,
              minimumAdvance: const Duration(seconds: 1),
              label: 'fullscreen injected playback',
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

Future<bool> _waitForAudibleOrUnmuted(
  HLSVideoAdapter adapter, {
  Duration timeout = const Duration(seconds: 3),
}) async {
  final deadline = DateTime.now().add(timeout);
  var retries = 0;
  while (DateTime.now().isBefore(deadline)) {
    final muted = await adapter.isMutedNative();
    final diagnostics = await adapter.getPlaybackDiagnostics();
    final volume = (diagnostics['volume'] as num?)?.toDouble() ?? 0.0;
    if (!muted && volume >= 0.95) {
      return true;
    }
    if (retries < 2) {
      retries += 1;
      await adapter.setVolume(1);
    }
    await Future<void>.delayed(const Duration(milliseconds: 180));
  }
  return false;
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
  return waitForPlayerPlayable(
    tester,
    cacheKey: sample.docId,
    label: label,
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
  }

  throw TestFailure(
    '$label did not advance playback '
    '(playing=${adapter.value.isPlaying}, position=${adapter.value.position}, '
    'duration=${adapter.value.duration}).',
  );
}
