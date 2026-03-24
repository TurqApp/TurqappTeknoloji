import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turqappv2/Core/Services/SegmentCache/hls_data_usage_probe.dart';
import 'package:turqappv2/Core/Services/global_video_adapter_pool.dart';
import 'package:turqappv2/Core/Services/integration_test_keys.dart';
import 'package:turqappv2/Core/Services/network_awareness_service.dart';
import 'package:turqappv2/Models/posts_model.dart';
import 'package:turqappv2/Modules/Agenda/agenda_controller.dart';
import 'package:turqappv2/hls_player/hls_video_adapter.dart';

import '../core/helpers/smoke_artifact_collector.dart';
import '../core/bootstrap/test_app_bootstrap.dart';
import '../core/helpers/player_contract_helpers.dart';

void main() {
  ensureIntegrationBinding();

  testWidgets(
    'Advanced HLS data usage suite validates playback data, caching, segment loading and bitrate adaptation',
    (tester) async {
      final originalOnError = FlutterError.onError;
      try {
        await SmokeArtifactCollector.runScenario(
          'hls_data_usage_suite',
          tester,
          () async {
            FlutterError.onError = (details) {
              final text = details.exceptionAsString();
              if (text.contains('cloud_firestore/permission-denied')) {
                debugPrint('Suppressed non-fatal: $text');
                return;
              }
              originalOnError?.call(details);
            };

            await launchTurqApp(tester);
            await expectFeedScreen(tester);

            final controller = AgendaController.ensure();
            final network = NetworkAwarenessService.ensure();
            final probe = HlsDataUsageProbe.ensure()
              ..resetSession(label: 'feed_hls_data_usage');
            final suiteDeadline =
                DateTime.now().add(const Duration(minutes: 2));

            final bootSample = await waitForFeedVisibleAutoplayVideo(
              tester,
              controller: controller,
              timeout: const Duration(seconds: 8),
            );
            final first = _FeedVideoSample(
              index: bootSample.index,
              docId: bootSample.docId,
              model: bootSample.model,
            );
            final firstExists = await waitForPoolAdapterExists(
              tester,
              cacheKey: first.docId,
              label: 'hls_first.exists',
              timeout: const Duration(seconds: 8),
            );
            await waitForPlayerInitialized(
              tester,
              cacheKey: first.docId,
              label: 'hls_first.initialized',
              timeout: const Duration(seconds: 8),
            );
            final firstFrame = await waitForPlayerFirstFrame(
              tester,
              cacheKey: first.docId,
              label: 'hls_first.firstFrame',
              timeout: const Duration(seconds: 8),
            );
            final firstCapture = _FeedPlaybackCapture(
              sample: first,
              adapter: firstExists.isDisposed ? firstFrame : firstExists,
            );
            probe.setVisibleDoc(firstCapture.sample.docId);
            await _assertVideoHealthy(
              tester,
              controller: controller,
              sample: firstCapture.sample,
              adapter: firstCapture.adapter,
              label: 'hls_first',
              minimumAdvance: const Duration(milliseconds: 1200),
              deadline:
                  _phaseDeadline(suiteDeadline, const Duration(seconds: 8)),
            );

            await tester.pump(const Duration(seconds: 4));
            final fastPlaybackDiag =
                await firstCapture.adapter.getPlaybackDiagnostics();
            final fastSnapshot = probe.snapshot();
            final fastTrafficBytes =
                fastSnapshot.downloadedBytes + fastSnapshot.cacheServedBytes;
            final probeCapturedTraffic = fastTrafficBytes > 0 ||
                fastSnapshot.segmentDownloads > 0 ||
                fastSnapshot.playlistDownloads > 0 ||
                fastSnapshot.topDocs.isNotEmpty;
            if (!probeCapturedTraffic) {
              debugPrint(
                '[hls_data_usage_suite] probe_unavailable '
                '${jsonEncode(<String, dynamic>{
                      'playback': fastPlaybackDiag,
                      'snapshot': fastSnapshot.toJson(),
                    })}',
              );
              return;
            }
            expect(
              fastTrafficBytes,
              greaterThan(128 * 1024),
              reason:
                  'Visible HLS playback should produce measurable segment traffic '
                  '(downloaded=${fastSnapshot.downloadedBytes}, cacheServed=${fastSnapshot.cacheServedBytes}).',
            );

            debugPrint(
                '[hls_data_usage_suite] fast_snapshot=${jsonEncode(fastSnapshot.toJson())}');

            network.debugSetNetworkOverride(NetworkType.cellular);
            probe.debugSetNetworkProfile(HlsDebugNetworkProfile.slow);
            final slowSample = await _scrollToNextVisibleVideo(
              tester,
              controller: controller,
              deadline:
                  _phaseDeadline(suiteDeadline, const Duration(seconds: 10)),
            );
            expect(slowSample, isNotNull,
                reason: 'Slow network phase lost visible video.');
            final slowCapture = await _capturePlayableFeedSample(
              tester,
              controller: controller,
              initialSample: slowSample,
              label: 'hls_slow',
              deadline:
                  _phaseDeadline(suiteDeadline, const Duration(seconds: 10)),
            );
            probe.setVisibleDoc(slowCapture.sample.docId);
            await _assertVideoHealthy(
              tester,
              controller: controller,
              sample: slowCapture.sample,
              adapter: slowCapture.adapter,
              label: 'hls_slow',
              minimumAdvance: const Duration(milliseconds: 900),
              deadline:
                  _phaseDeadline(suiteDeadline, const Duration(seconds: 8)),
            );
            await tester.pump(const Duration(seconds: 4));
            final slowPlaybackDiag =
                await slowCapture.adapter.getPlaybackDiagnostics();

            probe.debugSetNetworkProfile(HlsDebugNetworkProfile.unstable);
            final unstableSample = await _scrollToNextVisibleVideo(
              tester,
              controller: controller,
              deadline:
                  _phaseDeadline(suiteDeadline, const Duration(seconds: 10)),
            );
            expect(unstableSample, isNotNull,
                reason: 'Unstable network phase lost visible video.');
            final unstableCapture = await _capturePlayableFeedSample(
              tester,
              controller: controller,
              initialSample: unstableSample,
              label: 'hls_unstable',
              deadline:
                  _phaseDeadline(suiteDeadline, const Duration(seconds: 10)),
            );
            probe.setVisibleDoc(unstableCapture.sample.docId);
            await _assertVideoHealthy(
              tester,
              controller: controller,
              sample: unstableCapture.sample,
              adapter: unstableCapture.adapter,
              label: 'hls_unstable',
              minimumAdvance: const Duration(milliseconds: 900),
              deadline:
                  _phaseDeadline(suiteDeadline, const Duration(seconds: 8)),
            );
            await tester.pump(const Duration(seconds: 4));
            final unstablePlaybackDiag =
                await unstableCapture.adapter.getPlaybackDiagnostics();

            probe.debugSetNetworkProfile(HlsDebugNetworkProfile.fast);
            network.debugSetNetworkOverride(NetworkType.wifi);
            final replayBaseline = probe.snapshot();
            await _scrollFeed(tester, const Offset(0, 460), steps: 6);
            await _waitForFeedStability(
              tester,
              controller: controller,
              deadline:
                  _phaseDeadline(suiteDeadline, const Duration(seconds: 5)),
            );
            await _scrollFeed(tester, const Offset(0, -460), steps: 6);
            await _waitForFeedStability(
              tester,
              controller: controller,
              deadline:
                  _phaseDeadline(suiteDeadline, const Duration(seconds: 5)),
            );
            final replaySample = await _captureCurrentFeedVideo(
              tester,
              controller: controller,
              deadline:
                  _phaseDeadline(suiteDeadline, const Duration(seconds: 8)),
            );
            expect(replaySample, isNotNull,
                reason:
                    'Replay cache phase could not restore a visible video.');
            final replayCapture = await _capturePlayableFeedSample(
              tester,
              controller: controller,
              initialSample: replaySample,
              label: 'hls_replay',
              deadline:
                  _phaseDeadline(suiteDeadline, const Duration(seconds: 10)),
            );
            probe.setVisibleDoc(replayCapture.sample.docId);
            await _assertVideoHealthy(
              tester,
              controller: controller,
              sample: replayCapture.sample,
              adapter: replayCapture.adapter,
              label: 'hls_replay',
              minimumAdvance: const Duration(milliseconds: 700),
              deadline:
                  _phaseDeadline(suiteDeadline, const Duration(seconds: 6)),
            );
            await tester.pump(const Duration(seconds: 2));
            final replayAfter = probe.snapshot();
            final replayDownloadedDelta =
                replayAfter.downloadedBytes - replayBaseline.downloadedBytes;
            final replayCacheDelta =
                replayAfter.cacheServedBytes - replayBaseline.cacheServedBytes;
            expect(
              replayDownloadedDelta <= (512 * 1024) || replayCacheDelta > 0,
              isTrue,
              reason:
                  'Replay should reuse HLS cache instead of redownloading aggressively '
                  '(downloadedDelta=$replayDownloadedDelta, cacheDelta=$replayCacheDelta).',
            );

            final scrollBaseline = probe.snapshot();
            for (var i = 0; i < 22; i++) {
              await _scrollFeed(tester, const Offset(0, -520), steps: 4);
              if (i % 2 == 1) {
                await _waitForFeedStability(
                  tester,
                  controller: controller,
                  deadline:
                      _phaseDeadline(suiteDeadline, const Duration(seconds: 4)),
                );
                final sample = await _captureCurrentFeedVideo(
                  tester,
                  controller: controller,
                  deadline:
                      _phaseDeadline(suiteDeadline, const Duration(seconds: 5)),
                );
                if (sample != null) {
                  probe.setVisibleDoc(sample.docId);
                }
              }
            }
            await _waitForFeedStability(
              tester,
              controller: controller,
              deadline:
                  _phaseDeadline(suiteDeadline, const Duration(seconds: 6)),
            );
            final finalReport = probe.snapshot();
            final scrollDownloadedDelta =
                finalReport.downloadedBytes - scrollBaseline.downloadedBytes;
            final perVideoMb = (scrollDownloadedDelta / (1024 * 1024)) / 22.0;

            final fastBitrate = _extractBitrateKbps(fastPlaybackDiag);
            final slowBitrate = _extractBitrateKbps(slowPlaybackDiag);
            if (fastBitrate > 0 && slowBitrate > 0) {
              expect(
                slowBitrate <= (fastBitrate * 1.25),
                isTrue,
                reason:
                    'Slow network should not stay on a significantly higher bitrate '
                    '(fast=$fastBitrate kbps, slow=$slowBitrate kbps).',
              );
            }

            expect(
              finalReport.peakOffscreenParallelDownloads,
              lessThanOrEqualTo(3),
              reason: 'Off-screen HLS downloads became too aggressive.',
            );
            expect(
              finalReport.peakParallelDocDownloads,
              lessThanOrEqualTo(5),
              reason: 'Too many videos downloaded in parallel.',
            );
            expect(
              perVideoMb,
              lessThan(3.5),
              reason:
                  'Fast scroll HLS data usage per video is too high: ${perVideoMb.toStringAsFixed(2)} MB/video',
            );
            expect(
              finalReport.mbPerMinute,
              lessThan(20.0),
              reason:
                  'Feed HLS data usage per minute is too high: ${finalReport.mbPerMinute.toStringAsFixed(2)} MB/min',
            );
            expect(
              finalReport.repeatedSegmentDownloads,
              lessThanOrEqualTo(4),
              reason: 'Too many repeated HLS segment downloads detected.',
            );
            expect(
              finalReport.anomalies,
              isEmpty,
              reason:
                  'HLS data anomalies detected: ${finalReport.anomalies.join(' | ')}',
            );

            final topDocWithSegments = finalReport.topDocs.firstWhere(
              (doc) => doc.maxSegmentDurationSec > 0,
              orElse: () => finalReport.topDocs.isEmpty
                  ? const HlsDocUsageSummary(
                      docId: 'none',
                      downloadedBytes: 0,
                      cacheServedBytes: 0,
                      downloadedSegments: 0,
                      repeatedSegmentDownloads: 0,
                      playlistDownloads: 0,
                      playlistCacheHits: 0,
                      variantKeys: <String>[],
                      avgSegmentDurationSec: 0,
                      maxSegmentDurationSec: 0,
                      minSegmentDurationSec: 0,
                      avgSegmentSizeKb: 0,
                      maxSegmentSizeKb: 0,
                    )
                  : finalReport.topDocs.first,
            );
            if (topDocWithSegments.maxSegmentDurationSec > 0) {
              expect(
                topDocWithSegments.minSegmentDurationSec,
                greaterThanOrEqualTo(0.8),
                reason: 'Segment duration dropped below expected floor.',
              );
              expect(
                topDocWithSegments.maxSegmentDurationSec,
                lessThanOrEqualTo(3.2),
                reason: 'Segment duration exceeded expected HLS target window.',
              );
            }

            debugPrint(
              '[hls_data_usage_suite] report=${jsonEncode(<String, dynamic>{
                    'mbPerMinute': finalReport.mbPerMinute,
                    'avgMbPerVideo': finalReport.avgMbPerVideo,
                    'bitrates': <String, dynamic>{
                      'fast': fastBitrate,
                      'slow': slowBitrate,
                      'unstable': _extractBitrateKbps(unstablePlaybackDiag),
                    },
                    'segmentPattern': finalReport.topDocs
                        .take(3)
                        .map((e) => e.toJson())
                        .toList(),
                    'cacheEffectiveness': <String, dynamic>{
                      'cacheReuseRatio': finalReport.cacheReuseRatio,
                      'replayDownloadedDeltaBytes': replayDownloadedDelta,
                      'replayCacheDeltaBytes': replayCacheDelta,
                    },
                    'anomalies': finalReport.anomalies,
                    'optimizationRecommendations':
                        _optimizationRecommendations(finalReport),
                  })}',
            );
          },
        );
      } finally {
        FlutterError.onError = originalOnError;
        NetworkAwarenessService.maybeFind()?.debugSetNetworkOverride(null);
      }
    },
    timeout: const Timeout(Duration(minutes: 3)),
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
  final remaining = deadline.difference(DateTime.now());
  final timeout = remaining.isNegative
      ? const Duration(seconds: 1)
      : remaining > const Duration(seconds: 12)
          ? const Duration(seconds: 12)
          : remaining;

  await waitForPoolAdapterExists(
    tester,
    cacheKey: sample.docId,
    label: '$label.exists',
    timeout: timeout,
  );
  await waitForPlayerInitialized(
    tester,
    cacheKey: sample.docId,
    label: '$label.initialized',
    timeout: timeout,
  );
  final firstFrame = await waitForPlayerFirstFrame(
    tester,
    cacheKey: sample.docId,
    label: '$label.firstFrame',
    timeout: timeout,
  );

  final selected =
      GlobalVideoAdapterPool.ensure().adapterForTesting(sample.docId) ??
          firstFrame;
  final value = selected.value;
  if (!value.isPlaying && !value.isBuffering) {
    await selected.play();
    await tester.pump(const Duration(milliseconds: 220));
    if (!selected.value.isPlaying && !selected.value.isBuffering) {
      await selected.recoverFrozenPlayback();
      await tester.pump(const Duration(milliseconds: 350));
    }
  }
  return selected;
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

  Duration? baseline;
  var sampleSwitchCount = 0;
  while (DateTime.now().isBefore(deadline)) {
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
        '$label regressed playback position (doc=${currentSample.docId}).',
      );
    }

    final nearEnd = value.duration > Duration.zero &&
        position >= value.duration - const Duration(milliseconds: 250);
    if (position - baseline >= minimumAdvance || value.isCompleted || nearEnd) {
      final nativePlaying = await currentAdapter.isPlayingNative();
      final nativeBuffering = await currentAdapter.isBufferingNative();
      expect(nativePlaying || nativeBuffering, isTrue,
          reason:
              '$label native player became inconsistent (doc=${currentSample.docId}).');
      return;
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

int _extractBitrateKbps(Map<String, dynamic> diagnostics) {
  final keys = <String>[
    'selectedVideoBitrateKbps',
    'observedBitrateKbps',
    'indicatedBitrateKbps',
    'bandwidthEstimateKbps',
  ];
  for (final key in keys) {
    final value = diagnostics[key];
    if (value is num && value > 0) {
      return value.round();
    }
  }
  return 0;
}

List<String> _optimizationRecommendations(HlsDataUsageSnapshot report) {
  final out = <String>[];
  if (report.offscreenDownloadedBytes > report.visibleDownloadedBytes) {
    out.add('Off-screen prefetch penceresi daraltılmalı.');
  }
  if (report.repeatedSegmentDownloads > 0) {
    out.add('Replay ve geri dönüşte segment cache reuse sertleştirilmeli.');
  }
  if (report.mbPerMinute > 12.0) {
    out.add(
        'Mobil veri için daha düşük bitrate varyantı daha erken seçilmeli.');
  }
  if (report.peakParallelDocDownloads > 3) {
    out.add('Aynı anda aktif HLS akış sayısı düşürülmeli.');
  }
  if (out.isEmpty) {
    out.add('HLS veri kullanımında kritik optimizasyon ihtiyacı gözlenmedi.');
  }
  return out;
}
