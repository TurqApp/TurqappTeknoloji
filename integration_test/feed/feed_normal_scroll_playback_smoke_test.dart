import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turqappv2/Core/Services/integration_test_keys.dart';
import 'package:turqappv2/Models/posts_model.dart';
import 'package:turqappv2/Modules/Agenda/agenda_controller.dart';
import 'package:turqappv2/hls_player/hls_video_adapter.dart';

import '../core/helpers/smoke_artifact_collector.dart';
import '../core/helpers/player_contract_helpers.dart';
import '../core/bootstrap/test_app_bootstrap.dart';

void main() {
  ensureIntegrationBinding();

  testWidgets(
    'Feed normal scroll keeps next autoplay videos advancing',
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
          'feed_normal_scroll_playback_smoke',
          tester,
          () async {
            await launchTurqApp(tester);
            await expectFeedScreen(tester);

            final controller = ensureAgendaController();
            await _waitForFeedStability(
              tester,
              controller: controller,
            );
            final first = await _captureCurrentFeedVideo(
              tester,
              controller: controller,
              timeout: const Duration(seconds: 8),
            );
            expect(first, isNotNull,
                reason: 'No initial autoplay feed video found.');
            final firstAdapter = await _waitForFeedAdapter(
              tester,
              sample: first!,
              label: 'initial',
              timeout: const Duration(seconds: 8),
            );
            await _assertAdvance(
              tester,
              sample: first,
              adapter: firstAdapter,
              label: 'initial',
              minimumAdvance: const Duration(milliseconds: 900),
              timeout: const Duration(seconds: 5),
            );

            for (var i = 0; i < 3; i++) {
              await tester.drag(
                byItKey(IntegrationTestKeys.screenFeed),
                const Offset(0, -380),
              );
              await _waitForFeedStability(
                tester,
                controller: controller,
              );
              await expectNoFlutterException(tester);

              final sample = await _captureCurrentFeedVideo(
                tester,
                controller: controller,
                timeout: const Duration(seconds: 6),
              );
              expect(sample, isNotNull,
                  reason:
                      'No autoplay video found after normal scroll step $i.');
              final adapter = await _waitForFeedAdapter(
                tester,
                sample: sample!,
                label: 'normal_scroll_$i',
                timeout: const Duration(seconds: 6),
              );
              await _assertAdvance(
                tester,
                sample: sample,
                adapter: adapter,
                label: 'normal_scroll_$i',
                minimumAdvance: const Duration(milliseconds: 900),
                timeout: const Duration(seconds: 5),
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

Future<void> _waitForFeedStability(
  WidgetTester tester, {
  required AgendaController controller,
  Duration timeout = const Duration(seconds: 4),
}) async {
  const step = Duration(milliseconds: 180);
  final maxTicks = timeout.inMilliseconds ~/ step.inMilliseconds;
  String? lastSignature;
  var stableTicks = 0;

  for (var i = 0; i < maxTicks; i++) {
    await tester.pump(step);
    final topDocIds = controller.agendaList
        .take(8)
        .map((post) => post.docID.trim())
        .join('|');
    final signature =
        '${controller.agendaList.length}:${controller.centeredIndex.value}:$topDocIds';
    if (signature == lastSignature) {
      stableTicks += 1;
      if (stableTicks >= 3) {
        return;
      }
    } else {
      lastSignature = signature;
      stableTicks = 0;
    }
  }
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
  required Duration timeout,
}) async {
  const step = Duration(milliseconds: 200);
  final maxTicks = timeout.inMilliseconds ~/ step.inMilliseconds;
  for (var i = 0; i < maxTicks; i++) {
    await tester.pump(step);
    final centered = controller.centeredIndex.value;
    if (centered < 0 || centered >= controller.agendaList.length) continue;
    final post = controller.agendaList[centered];
    if (!controller.canAutoplayInTests(post)) continue;
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
  required Duration timeout,
}) async {
  return waitForPlayerPlayable(
    tester,
    cacheKey: sample.docId,
    label: label,
    timeout: timeout,
  );
}

Future<void> _assertAdvance(
  WidgetTester tester, {
  required _FeedVideoSample sample,
  required HLSVideoAdapter adapter,
  required String label,
  required Duration minimumAdvance,
  required Duration timeout,
}) async {
  final muted = await adapter.isMutedNative();
  if (muted) {
    final becameAudible = await _waitForAudibleOrUnmuted(adapter);
    expect(
      becameAudible,
      isTrue,
      reason:
          '$label stayed muted beyond the audible grace window (doc=${sample.docId}).',
    );
  }

  const step = Duration(milliseconds: 220);
  final maxTicks = timeout.inMilliseconds ~/ step.inMilliseconds;
  Duration? baseline;
  for (var i = 0; i < maxTicks; i++) {
    await tester.pump(step);
    final value = adapter.value;
    if (adapter.isDisposed || !value.isInitialized) {
      throw TestFailure(
          '$label disposed or lost initialization (doc=${sample.docId}).');
    }
    final position = value.position;
    baseline ??= position > Duration.zero ? position : null;
    if (baseline == null) continue;
    if (position - baseline >= minimumAdvance) {
      return;
    }
    if (i == maxTicks ~/ 2 && value.isPlaying) {
      await adapter.recoverFrozenPlayback();
    }
  }

  throw TestFailure(
    '$label did not advance enough '
    '(doc=${sample.docId}, playing=${adapter.value.isPlaying}, '
    'position=${adapter.value.position}, duration=${adapter.value.duration}).',
  );
}

Future<bool> _waitForAudibleOrUnmuted(
  HLSVideoAdapter adapter, {
  Duration timeout = const Duration(seconds: 2),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    final muted = await adapter.isMutedNative();
    final diagnostics = await adapter.getPlaybackDiagnostics();
    final volume = (diagnostics['volume'] as num?)?.toDouble() ?? 0.0;
    if (!muted && volume >= 0.95) {
      return true;
    }
    await Future<void>.delayed(const Duration(milliseconds: 180));
  }
  return false;
}
