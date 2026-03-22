import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turqappv2/Core/Services/global_video_adapter_pool.dart';
import 'package:turqappv2/Core/Services/integration_test_keys.dart';
import 'package:turqappv2/Models/posts_model.dart';
import 'package:turqappv2/Modules/Agenda/agenda_controller.dart';
import 'package:turqappv2/hls_player/hls_video_adapter.dart';

import '../core/bootstrap/test_app_bootstrap.dart';
import '../core/helpers/perf_monitor.dart';
import '../core/helpers/smoke_artifact_collector.dart';
import '../core/helpers/test_state_probe.dart';

void main() {
  ensureIntegrationBinding();

  testWidgets(
    'Feed 15 minute long-session stress preserves playback health and memory trend',
    (tester) async {
      final perf = PerfMonitor()..start();

      try {
        await SmokeArtifactCollector.runScenario(
          'feed_long_session_15m_stress',
          tester,
          () async {
            await launchTurqApp(tester);
            await expectFeedScreen(tester);

            final controller = AgendaController.ensure();
            final pool = GlobalVideoAdapterPool.ensure();
            final suiteDeadline =
                DateTime.now().add(const Duration(minutes: 15));
            final seenDocIds = <String>{};

            await _waitForFeedStability(
              tester,
              controller: controller,
              deadline:
                  _phaseDeadline(suiteDeadline, const Duration(seconds: 10)),
            );

            final baselineSample = await _captureCurrentFeedVideo(
              tester,
              controller: controller,
              deadline:
                  _phaseDeadline(suiteDeadline, const Duration(seconds: 10)),
            );
            expect(
              baselineSample,
              isNotNull,
              reason:
                  'Long-session suite could not lock an initial playable video.',
            );
            final baselineAdapter = await _waitForFeedAdapter(
              tester,
              sample: baselineSample!,
              label: 'baseline',
              deadline:
                  _phaseDeadline(suiteDeadline, const Duration(seconds: 8)),
            );
            await _assertVideoHealthy(
              tester,
              controller: controller,
              sample: baselineSample,
              adapter: baselineAdapter,
              label: 'baseline',
              minimumAdvance: const Duration(milliseconds: 1200),
              deadline:
                  _phaseDeadline(suiteDeadline, const Duration(seconds: 8)),
            );
            seenDocIds.add(baselineSample.docId);

            final baselineProcess =
                await baselineAdapter.getProcessDiagnostics();
            var loop = 0;

            while (DateTime.now().isBefore(suiteDeadline)) {
              loop += 1;
              final direction = loop.isEven ? -520.0 : 420.0;
              await _scrollFeed(tester, Offset(0, direction), steps: 4);
              _assertFeedProbeHealthy();

              if (loop % 4 == 0) {
                await _waitForFeedStability(
                  tester,
                  controller: controller,
                  deadline:
                      _phaseDeadline(suiteDeadline, const Duration(seconds: 5)),
                );
                final sample = await _captureCurrentFeedVideo(
                  tester,
                  controller: controller,
                  deadline:
                      _phaseDeadline(suiteDeadline, const Duration(seconds: 7)),
                );
                expect(
                  sample,
                  isNotNull,
                  reason:
                      'Long-session suite lost active playable feed sample at loop $loop.',
                );
                final adapter = await _waitForFeedAdapter(
                  tester,
                  sample: sample!,
                  label: 'loop_$loop',
                  deadline:
                      _phaseDeadline(suiteDeadline, const Duration(seconds: 7)),
                );
                await _assertVideoHealthy(
                  tester,
                  controller: controller,
                  sample: sample,
                  adapter: adapter,
                  label: 'loop_$loop',
                  minimumAdvance: const Duration(milliseconds: 900),
                  deadline:
                      _phaseDeadline(suiteDeadline, const Duration(seconds: 6)),
                );
                seenDocIds.add(sample.docId);
              }

              if (loop % 18 == 0) {
                tester.binding.handleAppLifecycleStateChanged(
                  AppLifecycleState.inactive,
                );
                await tester.pump(const Duration(milliseconds: 120));
                tester.binding.handleAppLifecycleStateChanged(
                  AppLifecycleState.hidden,
                );
                await tester.pump(const Duration(milliseconds: 120));
                tester.binding.handleAppLifecycleStateChanged(
                  AppLifecycleState.paused,
                );
                await tester.pump(const Duration(milliseconds: 400));
                tester.binding.handleAppLifecycleStateChanged(
                  AppLifecycleState.hidden,
                );
                await tester.pump(const Duration(milliseconds: 120));
                tester.binding.handleAppLifecycleStateChanged(
                  AppLifecycleState.inactive,
                );
                await tester.pump(const Duration(milliseconds: 120));
                tester.binding.handleAppLifecycleStateChanged(
                  AppLifecycleState.resumed,
                );
                await tester.pump(const Duration(seconds: 2));
                await expectNoFlutterException(tester);
              }

              if (loop % 24 == 0) {
                debugPrint(
                  '[feed_long_session_15m_stress] progress=${DateTime.now().difference(suiteDeadline.subtract(const Duration(minutes: 15))).inMinutes}m loops=$loop validated=${seenDocIds.length}',
                );
              }
            }

            await _waitForFeedStability(
              tester,
              controller: controller,
              deadline: DateTime.now().add(const Duration(seconds: 8)),
            );
            final finalSample = await _captureCurrentFeedVideo(
              tester,
              controller: controller,
              deadline: DateTime.now().add(const Duration(seconds: 8)),
            );
            expect(finalSample, isNotNull,
                reason: 'Final long-session sample missing.');
            final finalAdapter = await _waitForFeedAdapter(
              tester,
              sample: finalSample!,
              label: 'final',
              deadline: DateTime.now().add(const Duration(seconds: 8)),
            );
            await _assertVideoHealthy(
              tester,
              controller: controller,
              sample: finalSample,
              adapter: finalAdapter,
              label: 'final',
              minimumAdvance: const Duration(milliseconds: 1200),
              deadline: DateTime.now().add(const Duration(seconds: 8)),
            );

            final perfReport = perf.stop();
            final finalProcess = await finalAdapter.getProcessDiagnostics();
            final finalPlayback = await finalAdapter.getPlaybackDiagnostics();
            final poolSnapshot = pool.debugSnapshot();
            final baselineMemory = _readProcessMemoryMb(baselineProcess);
            final finalMemory = _readProcessMemoryMb(finalProcess);

            expect(
              seenDocIds.length,
              greaterThanOrEqualTo(10),
              reason:
                  'Long-session suite should validate at least 10 unique videos.',
            );
            expect(
              finalMemory - baselineMemory,
              lessThan(300.0),
              reason:
                  'Long-session memory growth is too high (baseline=$baselineMemory MB, final=$finalMemory MB).',
            );
            expect(
              perfReport.severeJankRatio,
              lessThan(0.70),
              reason:
                  'Long-session severe jank ratio is too high (${perfReport.severeJankRatio}).',
            );

            debugPrint(
              '[feed_long_session_15m_stress] ${jsonEncode(<String, dynamic>{
                    'performance': perfReport.toJson(),
                    'baselineProcess': baselineProcess,
                    'finalProcess': finalProcess,
                    'finalPlayback': finalPlayback,
                    'pool': poolSnapshot,
                    'validatedVideos': seenDocIds.length,
                    'durationMinutes': 15,
                  })}',
            );
          },
        );
      } finally {
        perf.stop();
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

DateTime _phaseDeadline(DateTime suiteDeadline, Duration localWindow) {
  final localDeadline = DateTime.now().add(localWindow);
  return localDeadline.isBefore(suiteDeadline) ? localDeadline : suiteDeadline;
}

Future<void> _waitForFeedStability(
  WidgetTester tester, {
  required AgendaController controller,
  required DateTime deadline,
}) async {
  String? lastSignature;
  var stableTicks = 0;
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 180));
    final topDocIds =
        controller.agendaList.take(8).map((post) => post.docID).join('|');
    final signature =
        '${controller.agendaList.length}:${controller.centeredIndex.value}:$topDocIds';
    if (signature == lastSignature) {
      stableTicks += 1;
      if (stableTicks >= 3) return;
    } else {
      lastSignature = signature;
      stableTicks = 0;
    }
  }
}

Future<_FeedVideoSample?> _captureCurrentFeedVideo(
  WidgetTester tester, {
  required AgendaController controller,
  required DateTime deadline,
}) async {
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 200));
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
  required DateTime deadline,
}) async {
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 200));
    final adapter =
        GlobalVideoAdapterPool.ensure().adapterForTesting(sample.docId);
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

  final adapter =
      GlobalVideoAdapterPool.ensure().adapterForTesting(sample.docId);
  final value = adapter?.value;
  throw TestFailure(
    '$label did not reach playable adapter state '
    '(doc=${sample.docId}, exists=${adapter != null}, disposed=${adapter?.isDisposed}, '
    'initialized=${value?.isInitialized}, firstFrame=${value?.hasRenderedFirstFrame}, '
    'playing=${value?.isPlaying}, position=${value?.position}).',
  );
}

Future<void> _assertVideoHealthy(
  WidgetTester tester, {
  required AgendaController controller,
  required _FeedVideoSample sample,
  required HLSVideoAdapter adapter,
  required String label,
  required Duration minimumAdvance,
  required DateTime deadline,
}) async {
  var currentSample = sample;
  var currentAdapter = adapter;
  final playback = await adapter.getPlaybackDiagnostics();
  final playing = (playback['isPlaying'] as bool?) ?? false;
  final buffering = (playback['isBuffering'] as bool?) ?? false;
  final renderedFirstFrame =
      (playback['didRenderFirstFrame'] as bool?) ?? false;
  expect(
    renderedFirstFrame,
    isTrue,
    reason: '$label did not render first frame (doc=${sample.docId}).',
  );
  expect(
    playing || buffering,
    isTrue,
    reason:
        '$label is neither playing nor recovering from buffer (doc=${sample.docId}).',
  );

  Duration? baseline;
  var loopCount = 0;
  var sampleSwitchCount = 0;
  while (DateTime.now().isBefore(deadline)) {
    loopCount += 1;
    await tester.pump(const Duration(milliseconds: 220));
    final value = currentAdapter.value;
    if (currentAdapter.isDisposed || !value.isInitialized) {
      if (sampleSwitchCount < 3) {
        try {
          currentAdapter = await _waitForFeedAdapter(
            tester,
            sample: currentSample,
            label: '${label}_reattach',
            deadline: deadline,
          );
          baseline = null;
          loopCount = 0;
          sampleSwitchCount += 1;
          continue;
        } catch (_) {}
      }
      final replacement = await _captureCurrentFeedVideo(
        tester,
        controller: controller,
        deadline: deadline,
      );
      if (replacement != null && sampleSwitchCount < 3) {
        currentSample = replacement;
        currentAdapter = await _waitForFeedAdapter(
          tester,
          sample: replacement,
          label: '${label}_resettled',
          deadline: deadline,
        );
        baseline = null;
        loopCount = 0;
        sampleSwitchCount += 1;
        continue;
      }
      throw TestFailure(
        '$label disposed or lost initialization (doc=${currentSample.docId}).',
      );
    }
    final position = value.position;
    baseline ??= position > Duration.zero ? position : null;
    if (baseline == null) {
      continue;
    }
    if (position < baseline) {
      throw TestFailure(
        '$label regressed playback position (doc=${sample.docId}).',
      );
    }
    final nearEnd = value.duration > Duration.zero &&
        position >= value.duration - const Duration(milliseconds: 250);
    final smokePlayableEnough = position >= const Duration(seconds: 2) &&
        (value.isPlaying || value.isBuffering);
    if (position - baseline >= minimumAdvance ||
        value.isCompleted ||
        nearEnd ||
        smokePlayableEnough) {
      final nativePlaying = await currentAdapter.isPlayingNative();
      final nativeBuffering = await currentAdapter.isBufferingNative();
      expect(
        nativePlaying || nativeBuffering,
        isTrue,
        reason:
            '$label native player fell into inconsistent state (doc=${currentSample.docId}).',
      );
      return;
    }
    if (loopCount == 6 && (value.isPlaying || position > baseline)) {
      await currentAdapter.recoverFrozenPlayback();
    }
  }

  throw TestFailure(
    '$label did not advance enough '
    '(doc=${currentSample.docId}, playing=${currentAdapter.value.isPlaying}, '
    'position=${currentAdapter.value.position}, duration=${currentAdapter.value.duration}).',
  );
}

Future<void> _scrollFeed(
  WidgetTester tester,
  Offset offset, {
  required int steps,
}) async {
  await tester.drag(byItKey(IntegrationTestKeys.screenFeed), offset);
  for (var i = 0; i < steps; i++) {
    await tester.pump(const Duration(milliseconds: 180));
  }
  await expectNoFlutterException(tester);
}

void _assertFeedProbeHealthy() {
  final payload = readSurfaceProbe('feed');
  final count = (payload['count'] as num?)?.toInt() ?? 0;
  final centeredIndex = (payload['centeredIndex'] as num?)?.toInt() ?? -1;
  final docIds = (payload['docIds'] as List?)
          ?.map((e) => e.toString())
          .toList(growable: false) ??
      const <String>[];

  expect(count, greaterThan(0),
      reason: 'Feed should not become empty during stress.');
  expect(
    centeredIndex,
    greaterThanOrEqualTo(0),
    reason: 'Feed centered index became invalid.',
  );
  expect(centeredIndex, lessThan(count),
      reason: 'Feed centered index out of bounds.');
  expect(
    docIds.where((id) => id.trim().isNotEmpty),
    isNotEmpty,
    reason: 'Feed doc list should not go blank.',
  );
}

double _readProcessMemoryMb(Map<String, dynamic> payload) {
  final pss = (payload['pssMb'] as num?)?.toDouble();
  if (pss != null && pss > 0) return pss;
  final resident = (payload['residentMemoryMb'] as num?)?.toDouble();
  if (resident != null && resident > 0) return resident;
  final javaHeap = (payload['javaHeapMb'] as num?)?.toDouble() ?? 0;
  final nativeHeap = (payload['nativeHeapMb'] as num?)?.toDouble() ?? 0;
  return javaHeap + nativeHeap;
}
