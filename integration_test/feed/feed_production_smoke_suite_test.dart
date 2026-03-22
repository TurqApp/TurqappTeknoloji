import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turqappv2/Core/Services/global_video_adapter_pool.dart';
import 'package:turqappv2/Core/Services/integration_test_keys.dart';
import 'package:turqappv2/Core/Services/network_awareness_service.dart';
import 'package:turqappv2/Models/posts_model.dart';
import 'package:turqappv2/Modules/Agenda/agenda_controller.dart';
import 'package:turqappv2/hls_player/hls_video_adapter.dart';

import '../core/helpers/perf_monitor.dart';
import '../core/helpers/smoke_artifact_collector.dart';
import '../core/bootstrap/test_app_bootstrap.dart';
import '../core/helpers/test_state_probe.dart';

void main() {
  ensureIntegrationBinding();

  testWidgets(
    'Feed production smoke suite validates playback, scroll, perf, stability and network resilience',
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

      final perf = PerfMonitor()..start();

      try {
        await SmokeArtifactCollector.runScenario(
          'feed_production_smoke_suite',
          tester,
          () async {
            await launchTurqApp(tester);
            await expectFeedScreen(tester);

            final controller = AgendaController.ensure();
            final network = NetworkAwarenessService.ensure();
            final pool = GlobalVideoAdapterPool.ensure();
            final suiteDeadline = DateTime.now().add(const Duration(minutes: 2));
            final seenDocIds = <String>{};

            debugPrint('[feed_production_smoke_suite] phase=initial');
            await _waitForFeedStability(
              tester,
              controller: controller,
              deadline: _phaseDeadline(suiteDeadline, const Duration(seconds: 8)),
            );

            final firstSample = await _captureCurrentFeedVideo(
              tester,
              controller: controller,
              deadline: _phaseDeadline(suiteDeadline, const Duration(seconds: 8)),
            );
            expect(firstSample, isNotNull, reason: 'Feed did not expose a first autoplay video.');
            final firstAdapter = await _waitForFeedAdapter(
              tester,
              sample: firstSample!,
              label: 'feed_first',
              deadline: _phaseDeadline(suiteDeadline, const Duration(seconds: 8)),
            );
            await _assertVideoHealthy(
              tester,
              controller: controller,
              sample: firstSample,
              adapter: firstAdapter,
              label: 'feed_first',
              minimumAdvance: const Duration(milliseconds: 900),
              deadline: _phaseDeadline(suiteDeadline, const Duration(seconds: 8)),
            );
            await _assertAudioToggleWorks(firstAdapter, label: 'feed_first');
            seenDocIds.add(firstSample.docId);

            final baselineProcess = await firstAdapter.getProcessDiagnostics();

            for (var i = 0; i < 5; i++) {
              debugPrint('[feed_production_smoke_suite] phase=normal_scroll step=$i');
              await _scrollFeed(tester, const Offset(0, -380), steps: 8);
              await _waitForFeedStability(
                tester,
                controller: controller,
                deadline: _phaseDeadline(suiteDeadline, const Duration(seconds: 4)),
              );
              final sample = await _captureCurrentFeedVideo(
                tester,
                controller: controller,
                deadline: _phaseDeadline(suiteDeadline, const Duration(seconds: 6)),
              );
              expect(sample, isNotNull, reason: 'Normal scroll did not settle on a playable video.');
              final adapter = await _waitForFeedAdapter(
                tester,
                sample: sample!,
                label: 'normal_scroll_$i',
                deadline: _phaseDeadline(suiteDeadline, const Duration(seconds: 6)),
              );
              await _assertVideoHealthy(
                tester,
                controller: controller,
                sample: sample,
                adapter: adapter,
                label: 'normal_scroll_$i',
                minimumAdvance: const Duration(milliseconds: 700),
                deadline: _phaseDeadline(suiteDeadline, const Duration(seconds: 6)),
              );
              seenDocIds.add(sample.docId);
              _assertFeedProbeHealthy();
            }

            for (var i = 0; i < 12; i++) {
              if (i == 0 || i == 5 || i == 11) {
                debugPrint('[feed_production_smoke_suite] phase=fast_scroll step=$i');
              }
              await _scrollFeed(tester, const Offset(0, -620), steps: 5);
              _assertFeedProbeHealthy();
            }

            for (var i = 0; i < 30; i++) {
              if (i % 5 == 0) {
                debugPrint('[feed_production_smoke_suite] phase=stress_scroll step=$i');
              }
              final direction = i.isEven ? -520.0 : 420.0;
              await _scrollFeed(tester, Offset(0, direction), steps: 3);
              if (i % 5 == 4) {
                await _waitForFeedStability(
                  tester,
                  controller: controller,
                  deadline: _phaseDeadline(suiteDeadline, const Duration(seconds: 4)),
                );
                final sample = await _captureCurrentFeedVideo(
                  tester,
                  controller: controller,
                  deadline: _phaseDeadline(suiteDeadline, const Duration(seconds: 6)),
                );
                expect(sample, isNotNull, reason: 'Aggressive scroll lost active video at loop $i.');
                final adapter = await _waitForFeedAdapter(
                  tester,
                  sample: sample!,
                  label: 'stress_$i',
                  deadline: _phaseDeadline(suiteDeadline, const Duration(seconds: 6)),
                );
                await _assertVideoHealthy(
                  tester,
                  controller: controller,
                  sample: sample,
                  adapter: adapter,
                  label: 'stress_$i',
                  minimumAdvance: const Duration(milliseconds: 900),
                  deadline: _phaseDeadline(suiteDeadline, const Duration(seconds: 5)),
                );
                seenDocIds.add(sample.docId);
              }
            }

            debugPrint('[feed_production_smoke_suite] phase=resume');
            tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
            await tester.pump(const Duration(milliseconds: 120));
            tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
            await tester.pump(const Duration(milliseconds: 120));
            tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
            await tester.pump(const Duration(milliseconds: 350));
            tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
            await tester.pump(const Duration(milliseconds: 120));
            tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
            await tester.pump(const Duration(milliseconds: 120));
            tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
            await tester.pump(const Duration(seconds: 2));
            await expectNoFlutterException(tester);
            await _waitForFeedStability(
              tester,
              controller: controller,
              deadline: _phaseDeadline(suiteDeadline, const Duration(seconds: 5)),
            );

            final resumedSample = await _captureCurrentFeedVideo(
              tester,
              controller: controller,
              deadline: _phaseDeadline(suiteDeadline, const Duration(seconds: 8)),
            );
            expect(resumedSample, isNotNull, reason: 'Feed did not recover after resume.');
            final resumedAdapter = await _waitForFeedAdapter(
              tester,
              sample: resumedSample!,
              label: 'resume',
              deadline: _phaseDeadline(suiteDeadline, const Duration(seconds: 6)),
            );
            await _assertVideoHealthy(
              tester,
              controller: controller,
              sample: resumedSample,
              adapter: resumedAdapter,
              label: 'resume',
              minimumAdvance: const Duration(milliseconds: 1200),
              deadline: _phaseDeadline(suiteDeadline, const Duration(seconds: 5)),
            );

            debugPrint('[feed_production_smoke_suite] phase=cellular');
            network.debugSetNetworkOverride(NetworkType.cellular);
            await tester.pump(const Duration(milliseconds: 500));
            await _waitForFeedStability(
              tester,
              controller: controller,
              deadline: _phaseDeadline(suiteDeadline, const Duration(seconds: 5)),
            );
            final cellularSample = await _captureCurrentFeedVideo(
              tester,
              controller: controller,
              deadline: _phaseDeadline(suiteDeadline, const Duration(seconds: 8)),
            );
            expect(cellularSample, isNotNull, reason: 'Cellular override lost active video.');
            final cellularAdapter = await _waitForFeedAdapter(
              tester,
              sample: cellularSample!,
              label: 'cellular',
              deadline: _phaseDeadline(suiteDeadline, const Duration(seconds: 6)),
            );
            await _assertVideoHealthy(
              tester,
              controller: controller,
              sample: cellularSample,
              adapter: cellularAdapter,
              label: 'cellular',
              minimumAdvance: const Duration(milliseconds: 900),
              deadline: _phaseDeadline(suiteDeadline, const Duration(seconds: 5)),
            );

            debugPrint('[feed_production_smoke_suite] phase=offline');
            network.debugSetNetworkOverride(NetworkType.none);
            await tester.pump(const Duration(milliseconds: 600));
            expect(byItKey(IntegrationTestKeys.screenFeed), findsOneWidget);
            expect(controller.agendaList, isNotEmpty, reason: 'Offline feed should keep cached items.');
            await _scrollFeed(tester, const Offset(0, -260), steps: 4);
            await _waitForFeedStability(
              tester,
              controller: controller,
              deadline: _phaseDeadline(suiteDeadline, const Duration(seconds: 4)),
            );
            _assertFeedProbeHealthy();
            network.debugSetNetworkOverride(null);

            debugPrint('[feed_production_smoke_suite] phase=final');
            await _waitForFeedStability(
              tester,
              controller: controller,
              deadline: _phaseDeadline(suiteDeadline, const Duration(seconds: 5)),
            );
            final finalSample = await _captureCurrentFeedVideo(
              tester,
              controller: controller,
              deadline: _phaseDeadline(suiteDeadline, const Duration(seconds: 8)),
            );
            expect(finalSample, isNotNull, reason: 'Final feed sample missing.');
            final finalAdapter = await _waitForFeedAdapter(
              tester,
              sample: finalSample!,
              label: 'final',
              deadline: _phaseDeadline(suiteDeadline, const Duration(seconds: 6)),
            );
            await _assertVideoHealthy(
              tester,
              controller: controller,
              sample: finalSample,
              adapter: finalAdapter,
              label: 'final',
              minimumAdvance: const Duration(milliseconds: 900),
              deadline: _phaseDeadline(suiteDeadline, const Duration(seconds: 5)),
            );

            final perfReport = perf.stop();
            final finalProcess = await finalAdapter.getProcessDiagnostics();
            final finalPlayback = await finalAdapter.getPlaybackDiagnostics();
            final poolSnapshot = pool.debugSnapshot();
            final baselineMemory = _readProcessMemoryMb(baselineProcess);
            final finalMemory = _readProcessMemoryMb(finalProcess);

            expect(seenDocIds.length, greaterThanOrEqualTo(5),
                reason: 'Feed smoke should validate at least 5 unique videos.');
            expect(
              finalMemory - baselineMemory,
              lessThan(220.0),
              reason:
                  'Feed memory grew too much under stress (baseline=$baselineMemory MB, final=$finalMemory MB).',
            );
            expect(
              perfReport.severeJankRatio,
              lessThan(0.65),
              reason:
                  'Feed severe jank ratio is too high (${perfReport.severeJankRatio}).',
            );

            debugPrint(
              '[feed_production_smoke_suite] ${jsonEncode(<String, dynamic>{
                'performance': perfReport.toJson(),
                'baselineProcess': baselineProcess,
                'finalProcess': finalProcess,
                'finalPlayback': finalPlayback,
                'pool': poolSnapshot,
                'validatedVideos': seenDocIds.length,
              })}',
            );
          },
        );
      } finally {
        perf.stop();
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
  var recoveryAttempts = 0;
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 200));
    final adapter = GlobalVideoAdapterPool.ensure().adapterForTesting(sample.docId);
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

  final adapter = GlobalVideoAdapterPool.ensure().adapterForTesting(sample.docId);
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
  var playing = (playback['isPlaying'] as bool?) ?? false;
  var buffering = (playback['isBuffering'] as bool?) ?? false;
  final renderedFirstFrame =
      (playback['didRenderFirstFrame'] as bool?) ?? false;
  expect(renderedFirstFrame, isTrue,
      reason: '$label did not render first frame (doc=${sample.docId}).');
  if (!playing && !buffering) {
    await adapter.play();
    await tester.pump(const Duration(milliseconds: 250));
    playing = currentAdapter.value.isPlaying;
    buffering = currentAdapter.value.isBuffering;
    if (!playing && !buffering) {
      await currentAdapter.recoverFrozenPlayback();
      await tester.pump(const Duration(milliseconds: 350));
      playing = currentAdapter.value.isPlaying;
      buffering = currentAdapter.value.isBuffering;
    }
  }
  expect(playing || buffering, isTrue,
      reason:
          '$label is neither playing nor recovering from buffer (doc=${sample.docId}).');

  final initiallyMuted = await adapter.isMutedNative();
  expect(initiallyMuted, isFalse,
      reason: '$label started muted unexpectedly (doc=${sample.docId}).');

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
      if (replacement != null &&
          sampleSwitchCount < 3) {
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
      throw TestFailure('$label regressed playback position (doc=${sample.docId}).');
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
      expect(nativePlaying || nativeBuffering, isTrue,
          reason:
              '$label native player fell into inconsistent state (doc=${currentSample.docId}).');
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

Future<void> _assertAudioToggleWorks(
  HLSVideoAdapter adapter, {
  required String label,
}) async {
  await adapter.setVolume(0);
  final muted = await adapter.isMutedNative();
  expect(muted, isTrue, reason: '$label failed mute toggle.');
  await adapter.setVolume(1);
  final unmuted = await adapter.isMutedNative();
  expect(unmuted, isFalse, reason: '$label failed unmute toggle.');
}

Future<void> _scrollFeed(
  WidgetTester tester,
  Offset offset, {
  required int steps,
}) async {
  await tester.drag(
    byItKey(IntegrationTestKeys.screenFeed),
    offset,
    warnIfMissed: false,
  );
  for (var i = 0; i < steps; i++) {
    await tester.pump(const Duration(milliseconds: 180));
  }
  await expectNoFlutterException(tester);
}

void _assertFeedProbeHealthy() {
  final payload = readSurfaceProbe('feed');
  final count = (payload['count'] as num?)?.toInt() ?? 0;
  final centeredIndex = (payload['centeredIndex'] as num?)?.toInt() ?? -1;
  final docIds = (payload['docIds'] as List?)?.map((e) => e.toString()).toList() ?? const <String>[];

  expect(count, greaterThan(0), reason: 'Feed should not become empty during smoke.');
  expect(centeredIndex, greaterThanOrEqualTo(0),
      reason: 'Feed centered index became invalid.');
  expect(centeredIndex, lessThan(count), reason: 'Feed centered index out of bounds.');
  expect(docIds.where((id) => id.trim().isNotEmpty), isNotEmpty,
      reason: 'Feed doc list should not go blank.');
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
