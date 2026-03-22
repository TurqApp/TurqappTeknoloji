import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turqappv2/Core/Services/global_video_adapter_pool.dart';
import 'package:turqappv2/Core/Services/integration_test_keys.dart';
import 'package:turqappv2/Models/posts_model.dart';
import 'package:turqappv2/Modules/Profile/MyProfile/profile_controller.dart';
import 'package:turqappv2/hls_player/hls_video_adapter.dart';

import '../core/helpers/smoke_artifact_collector.dart';
import '../core/bootstrap/test_app_bootstrap.dart';

void main() {
  ensureIntegrationBinding();

  testWidgets(
    'Profile feed keeps first ten video posts audible and advancing',
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
          'profile_feed_video_smoke',
          tester,
          () async {
            await launchTurqApp(tester);
            await tapItKey(tester, IntegrationTestKeys.navProfile, settlePumps: 12);
            expect(byItKey(IntegrationTestKeys.screenProfile), findsOneWidget);

            final controller = ProfileController.ensure();
            final seenDocIds = <String>{};
            var swipeAttempts = 0;

            while (seenDocIds.length < 10 && swipeAttempts < 28) {
              final sample = await _captureCurrentProfileVideo(
                tester,
                controller: controller,
              );
              if (sample != null && !seenDocIds.contains(sample.docId)) {
                await _assertProfileVideoHealthy(
                  tester,
                  controller: controller,
                  sample: sample,
                  label: 'profile video ${seenDocIds.length + 1}',
                );
                seenDocIds.add(sample.docId);
              }

              await tester.drag(
                byItKey(IntegrationTestKeys.screenProfile),
                const Offset(0, -420),
              );
              for (var i = 0; i < 10; i++) {
                await tester.pump(const Duration(milliseconds: 180));
              }
              await expectNoFlutterException(tester);
              swipeAttempts += 1;
            }

            expect(
              seenDocIds.length,
              greaterThanOrEqualTo(10),
              reason:
                  'Profile feed should expose at least 10 playable video posts during smoke scroll.',
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

class _ProfileVideoSample {
  const _ProfileVideoSample({
    required this.index,
    required this.docId,
    required this.isReshare,
    required this.model,
  });

  final int index;
  final String docId;
  final bool isReshare;
  final PostsModel model;
}

Future<_ProfileVideoSample?> _captureCurrentProfileVideo(
  WidgetTester tester, {
  required ProfileController controller,
}) async {
  const timeout = Duration(seconds: 8);
  const step = Duration(milliseconds: 200);
  final maxTicks = timeout.inMilliseconds ~/ step.inMilliseconds;

  for (var i = 0; i < maxTicks; i++) {
    await tester.pump(step);
    final centered = controller.centeredIndex.value;
    if (centered < 0 || centered >= controller.mergedPosts.length) {
      continue;
    }
    final entry = controller.mergedPosts[centered];
    final post = entry['post'];
    if (post is! PostsModel || !post.hasPlayableVideo) {
      continue;
    }
    final docId = ((entry['docID'] as String?) ?? post.docID).trim();
    if (docId.isEmpty) continue;
    return _ProfileVideoSample(
      index: centered,
      docId: docId,
      isReshare: entry['isReshare'] == true,
      model: post,
    );
  }
  return null;
}

Future<void> _assertProfileVideoHealthy(
  WidgetTester tester, {
  required ProfileController controller,
  required _ProfileVideoSample sample,
  required String label,
}) async {
  final adapter = await _waitForProfileAdapter(
    tester,
    controller: controller,
    sample: sample,
    label: label,
  );

  final initiallyMuted = await adapter.isMutedNative();
  if (initiallyMuted) {
    throw TestFailure('$label started muted (doc=${sample.docId}).');
  }

  await _waitForPlaybackAdvance(
    tester,
    adapter: adapter,
    minimumAdvance: const Duration(seconds: 2),
    label: label,
  );

  final mutedAfterAdvance = await adapter.isMutedNative();
  if (mutedAfterAdvance) {
    throw TestFailure('$label became muted after advance (doc=${sample.docId}).');
  }
}

Future<HLSVideoAdapter> _waitForProfileAdapter(
  WidgetTester tester, {
  required ProfileController controller,
  required _ProfileVideoSample sample,
  required String label,
}) async {
  const timeout = Duration(seconds: 8);
  const step = Duration(milliseconds: 200);
  final maxTicks = timeout.inMilliseconds ~/ step.inMilliseconds;
  final cacheKey = controller.agendaInstanceTag(
    docId: sample.docId,
    isReshare: sample.isReshare,
  );

  for (var i = 0; i < maxTicks; i++) {
    await tester.pump(step);
    final adapter = GlobalVideoAdapterPool.ensure().adapterForTesting(cacheKey);
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

  final adapter = GlobalVideoAdapterPool.ensure().adapterForTesting(cacheKey);
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
    final targetAdvance =
        remaining < minimumAdvance && remaining > const Duration(milliseconds: 400)
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
