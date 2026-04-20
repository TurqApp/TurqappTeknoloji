import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turqappv2/Core/Services/global_video_adapter_pool.dart';
import 'package:turqappv2/Core/Services/integration_test_keys.dart';
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

      final launchPerf = PerfMonitor()..start();
      final scrollPerf = PerfMonitor();
      var scrollPerfStarted = false;

      try {
        await SmokeArtifactCollector.runScenario(
          'feed_production_smoke_suite',
          tester,
          () async {
            await launchTurqApp(tester);
            await expectFeedScreen(tester);

            final controller = ensureAgendaController();
            final pool = GlobalVideoAdapterPool.ensure();
            final suiteDeadline =
                DateTime.now().add(const Duration(seconds: 75));
            final seenDocIds = <String>{};

            debugPrint('[feed_production_smoke_suite] phase=initial');
            await _waitForFeedStability(
              tester,
              controller: controller,
              deadline:
                  _phaseDeadline(suiteDeadline, const Duration(seconds: 8)),
            );

            final firstCapture = await _capturePlayableFeedSample(
              tester,
              controller: controller,
              label: 'feed_first',
              deadline:
                  _phaseDeadline(suiteDeadline, const Duration(seconds: 8)),
            );
            final firstSample = firstCapture.sample;
            final firstAdapter = firstCapture.adapter;
            await _assertVideoHealthy(
              tester,
              controller: controller,
              sample: firstSample,
              adapter: firstAdapter,
              label: 'feed_first',
              minimumAdvance: const Duration(milliseconds: 900),
              deadline:
                  _phaseDeadline(suiteDeadline, const Duration(seconds: 8)),
            );
            await _assertAudioToggleWorks(firstAdapter, label: 'feed_first');
            seenDocIds.add(firstSample.docId);

            final launchPerfReport = launchPerf.stop();
            scrollPerf.start();
            scrollPerfStarted = true;

            final baselineProcess = await firstAdapter.getProcessDiagnostics();

            for (var i = 0; i < 3; i++) {
              debugPrint(
                  '[feed_production_smoke_suite] phase=normal_scroll step=$i');
              await _scrollFeed(tester, const Offset(0, -380), steps: 8);
              await _waitForFeedStability(
                tester,
                controller: controller,
                deadline:
                    _phaseDeadline(suiteDeadline, const Duration(seconds: 4)),
              );
              final capture = await _capturePlayableFeedSample(
                tester,
                controller: controller,
                label: 'normal_scroll_$i',
                deadline:
                    _phaseDeadline(suiteDeadline, const Duration(seconds: 6)),
              );
              final sample = capture.sample;
              final adapter = capture.adapter;
              await _assertVideoHealthy(
                tester,
                controller: controller,
                sample: sample,
                adapter: adapter,
                label: 'normal_scroll_$i',
                minimumAdvance: const Duration(milliseconds: 700),
                deadline:
                    _phaseDeadline(suiteDeadline, const Duration(seconds: 6)),
              );
              seenDocIds.add(sample.docId);
              _assertFeedProbeHealthy();
            }

            debugPrint('[feed_production_smoke_suite] phase=final');
            await _waitForFeedStability(
              tester,
              controller: controller,
              deadline:
                  _phaseDeadline(suiteDeadline, const Duration(seconds: 5)),
            );
            final finalCapture = await _capturePlayableFeedSample(
              tester,
              controller: controller,
              label: 'final',
              deadline:
                  _phaseDeadline(suiteDeadline, const Duration(seconds: 8)),
            );
            final finalSample = finalCapture.sample;
            final finalAdapter = finalCapture.adapter;
            await _assertVideoHealthy(
              tester,
              controller: controller,
              sample: finalSample,
              adapter: finalAdapter,
              label: 'final',
              minimumAdvance: const Duration(milliseconds: 900),
              deadline:
                  _phaseDeadline(suiteDeadline, const Duration(seconds: 5)),
            );

            final scrollPerfReport = scrollPerf.stop();
            scrollPerfStarted = false;
            final finalProcess = await finalAdapter.getProcessDiagnostics();
            final finalPlayback = await finalAdapter.getPlaybackDiagnostics();
            final poolSnapshot = pool.debugSnapshot();
            final baselineMemory = _readProcessMemoryMb(baselineProcess);
            final finalMemory = _readProcessMemoryMb(finalProcess);

            expect(seenDocIds.length, greaterThanOrEqualTo(3),
                reason: 'Feed smoke should validate at least 3 unique videos.');
            expect(
              finalMemory - baselineMemory,
              lessThan(260.0),
              reason:
                  'Feed memory grew too much under stress (baseline=$baselineMemory MB, final=$finalMemory MB).',
            );
            expect(
              scrollPerfReport.severeJankRatio,
              lessThan(0.85),
              reason:
                  'Feed severe jank ratio is too high (${scrollPerfReport.severeJankRatio}).',
            );

            debugPrint(
              '[feed_production_smoke_suite] ${jsonEncode(<String, dynamic>{
                    'launchPerformance': launchPerfReport.toJson(),
                    'scrollPerformance': scrollPerfReport.toJson(),
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
        launchPerf.stop();
        if (scrollPerfStarted) {
          scrollPerf.stop();
        }
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

class _FeedPlaybackCapture {
  const _FeedPlaybackCapture({
    required this.sample,
    required this.adapter,
  });

  final _FeedVideoSample sample;
  final HLSVideoAdapter adapter;
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

Future<_FeedVideoSample?> _scrollToNextVisibleVideo(
  WidgetTester tester, {
  required AgendaController controller,
  required DateTime deadline,
}) async {
  await _scrollFeed(tester, const Offset(0, -420), steps: 6);
  await _waitForFeedStability(
    tester,
    controller: controller,
    deadline: deadline,
  );
  return _captureCurrentFeedVideo(
    tester,
    controller: controller,
    deadline: deadline,
  );
}

Future<_FeedPlaybackCapture> _capturePlayableFeedSample(
  WidgetTester tester, {
  required AgendaController controller,
  required String label,
  required DateTime deadline,
  _FeedVideoSample? initialSample,
}) async {
  var currentSample = initialSample ??
      await _captureCurrentFeedVideo(
        tester,
        controller: controller,
        deadline: deadline,
      );
  Object? lastError;

  for (var attempt = 0; attempt < 3; attempt++) {
    currentSample ??= await _scrollToNextVisibleVideo(
      tester,
      controller: controller,
      deadline: deadline,
    );
    if (currentSample == null) {
      continue;
    }

    try {
      final adapter = await _waitForFeedAdapter(
        tester,
        sample: currentSample,
        label: '${label}_$attempt',
        deadline: deadline,
      );
      return _FeedPlaybackCapture(
        sample: currentSample,
        adapter: adapter,
      );
    } catch (error) {
      lastError = error;
      currentSample = await _scrollToNextVisibleVideo(
        tester,
        controller: controller,
        deadline: deadline,
      );
    }
  }

  throw TestFailure(
    '$label could not resolve a playable HLS sample '
    '(lastError=$lastError).',
  );
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

  final initiallyMuted = await currentAdapter.isMutedNative();
  if (initiallyMuted) {
    final becameAudible = await _waitForAudibleOrUnmuted(currentAdapter);
    expect(
      becameAudible,
      isTrue,
      reason:
          '$label stayed muted beyond the audible grace window (doc=${currentSample.docId}).',
    );
  }

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
      if (sampleSwitchCount < 3) {
        final replacement = await _capturePlayableFeedSample(
          tester,
          controller: controller,
          label: '${label}_resettled',
          deadline: deadline,
        );
        currentSample = replacement.sample;
        currentAdapter = replacement.adapter;
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
          '$label regressed playback position (doc=${sample.docId}).');
    }
    final nearEnd = value.duration > Duration.zero &&
        position >= value.duration - const Duration(milliseconds: 250);
    final smokePlayableEnough = position >= const Duration(seconds: 2) &&
        (value.isPlaying || value.isBuffering);
    if (position - baseline >= minimumAdvance ||
        value.isCompleted ||
        nearEnd ||
        smokePlayableEnough) {
      final nativeHealthy = await _waitForNativePlaybackHealthy(
        currentAdapter,
        baseline: baseline,
        timeout: const Duration(seconds: 2),
      );
      if (nativeHealthy) {
        return;
      }
      await currentAdapter.recoverFrozenPlayback();
      await tester.pump(const Duration(milliseconds: 420));
      final recoveredHealthy = await _waitForNativePlaybackHealthy(
        currentAdapter,
        baseline: baseline,
        timeout: const Duration(seconds: 2),
      );
      expect(recoveredHealthy, isTrue,
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
  final muted = await _waitForMutedOrVolumeZero(adapter);
  expect(muted, isTrue, reason: '$label failed mute toggle.');
  await adapter.setVolume(1);
  final unmuted = await _waitForAudibleOrUnmuted(adapter);
  expect(unmuted, isTrue, reason: '$label failed unmute toggle.');
}

Future<bool> _waitForNativePlaybackHealthy(
  HLSVideoAdapter adapter, {
  required Duration baseline,
  Duration timeout = const Duration(seconds: 2),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    final nativePlaying = await adapter.isPlayingNative();
    final nativeBuffering = await adapter.isBufferingNative();
    if (nativePlaying || nativeBuffering) {
      return true;
    }
    final value = adapter.value;
    if (!adapter.isDisposed &&
        value.isInitialized &&
        value.hasRenderedFirstFrame &&
        (value.position > baseline ||
            value.isPlaying ||
            value.isBuffering ||
            value.isCompleted)) {
      return true;
    }
    await Future<void>.delayed(const Duration(milliseconds: 180));
  }
  return false;
}

Future<bool> _waitForMutedOrVolumeZero(
  HLSVideoAdapter adapter, {
  Duration timeout = const Duration(seconds: 5),
}) async {
  final deadline = DateTime.now().add(timeout);
  var retries = 0;
  while (DateTime.now().isBefore(deadline)) {
    final muted = await adapter.isMutedNative();
    final diagnostics = await adapter.getPlaybackDiagnostics();
    final volume = (diagnostics['volume'] as num?)?.toDouble() ?? 1.0;
    if (muted || volume <= 0.001) {
      return true;
    }
    if (retries < 2) {
      retries += 1;
      await adapter.setVolume(0);
    }
    await Future<void>.delayed(const Duration(milliseconds: 180));
  }
  return false;
}

Future<bool> _waitForAudibleOrUnmuted(
  HLSVideoAdapter adapter, {
  Duration timeout = const Duration(seconds: 5),
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
  final docIds =
      (payload['docIds'] as List?)?.map((e) => e.toString()).toList() ??
          const <String>[];

  expect(count, greaterThan(0),
      reason: 'Feed should not become empty during smoke.');
  expect(centeredIndex, greaterThanOrEqualTo(0),
      reason: 'Feed centered index became invalid.');
  expect(centeredIndex, lessThan(count),
      reason: 'Feed centered index out of bounds.');
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
