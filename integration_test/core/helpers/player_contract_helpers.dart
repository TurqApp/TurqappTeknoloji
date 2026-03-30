import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turqappv2/Core/Services/global_video_adapter_pool.dart';
import 'package:turqappv2/Models/posts_model.dart';
import 'package:turqappv2/Modules/Agenda/agenda_controller.dart';
import 'package:turqappv2/hls_player/hls_video_adapter.dart';

import 'test_state_probe.dart';

class FeedVisibleVideoSample {
  const FeedVisibleVideoSample({
    required this.index,
    required this.docId,
    required this.model,
  });

  final int index;
  final String docId;
  final PostsModel model;
}

Future<FeedVisibleVideoSample> waitForFeedVisibleAutoplayVideo(
  WidgetTester tester, {
  required AgendaController controller,
  Duration timeout = const Duration(seconds: 12),
  Duration step = const Duration(milliseconds: 200),
}) async {
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
    if (docId.isEmpty) {
      continue;
    }
    if (!_hasMountedFeedMediaSurface(tester, docId)) {
      continue;
    }
    return FeedVisibleVideoSample(
      index: centered,
      docId: docId,
      model: post,
    );
  }

  throw TestFailure(
    'Feed did not expose a visible autoplay video '
    '(count=${controller.agendaList.length}, centered=${controller.centeredIndex.value}, '
    'probe=${readIntegrationProbe()}).',
  );
}

bool _hasMountedFeedMediaSurface(WidgetTester tester, String docId) {
  final agendaSurface = find.byKey(Key('agenda-media-$docId'));
  if (agendaSurface.evaluate().isNotEmpty) {
    return true;
  }

  final classicSurface = find.byKey(Key('classic-media-$docId'));
  return classicSurface.evaluate().isNotEmpty;
}

Future<HLSVideoAdapter> waitForPoolAdapterExists(
  WidgetTester tester, {
  required String cacheKey,
  required String label,
  Duration timeout = const Duration(seconds: 8),
  Duration step = const Duration(milliseconds: 200),
}) async {
  final maxTicks = timeout.inMilliseconds ~/ step.inMilliseconds;

  for (var i = 0; i < maxTicks; i++) {
    await tester.pump(step);
    final candidates = _resolvePlaybackCacheKeyCandidates(cacheKey);
    for (final candidate in candidates) {
      final adapter =
          ensureGlobalVideoAdapterPool().adapterForTesting(candidate);
      if (adapter != null && !adapter.isDisposed) {
        return adapter;
      }
    }
  }

  throw TestFailure(
    '$label did not expose a player adapter '
    '(cacheKey=$cacheKey, feed=${readSurfaceProbe('feed')}, '
    'videoPlayback=${readSurfaceProbe('videoPlayback')}).',
  );
}

Future<HLSVideoAdapter> waitForPlayerInitialized(
  WidgetTester tester, {
  required String cacheKey,
  required String label,
  Duration timeout = const Duration(seconds: 8),
  Duration step = const Duration(milliseconds: 200),
}) async {
  final maxTicks = timeout.inMilliseconds ~/ step.inMilliseconds;

  for (var i = 0; i < maxTicks; i++) {
    await tester.pump(step);
    final candidates = _resolvePlaybackCacheKeyCandidates(cacheKey);
    for (final candidate in candidates) {
      final adapter =
          ensureGlobalVideoAdapterPool().adapterForTesting(candidate);
      final value = adapter?.value;
      if (adapter != null &&
          !adapter.isDisposed &&
          value != null &&
          value.isInitialized) {
        return adapter;
      }
    }
  }

  final adapter = _adapterForCandidates(_resolvePlaybackCacheKeyCandidates(
    cacheKey,
  ));
  throw TestFailure(
    '$label did not reach initialized player state '
    '(cacheKey=$cacheKey, exists=${adapter != null}, disposed=${adapter?.isDisposed}, '
    'initialized=${adapter?.value.isInitialized}, feed=${readSurfaceProbe('feed')}, '
    'videoPlayback=${readSurfaceProbe('videoPlayback')}).',
  );
}

Future<HLSVideoAdapter> waitForPlayerFirstFrame(
  WidgetTester tester, {
  required String cacheKey,
  required String label,
  Duration timeout = const Duration(seconds: 8),
  Duration step = const Duration(milliseconds: 200),
}) async {
  final maxTicks = timeout.inMilliseconds ~/ step.inMilliseconds;

  for (var i = 0; i < maxTicks; i++) {
    await tester.pump(step);
    final candidates = _resolvePlaybackCacheKeyCandidates(cacheKey);
    for (final candidate in candidates) {
      final adapter =
          ensureGlobalVideoAdapterPool().adapterForTesting(candidate);
      final value = adapter?.value;
      if (adapter != null &&
          !adapter.isDisposed &&
          value != null &&
          value.isInitialized &&
          value.hasRenderedFirstFrame) {
        return adapter;
      }
    }
  }

  final adapter = _adapterForCandidates(_resolvePlaybackCacheKeyCandidates(
    cacheKey,
  ));
  final value = adapter?.value;
  throw TestFailure(
    '$label did not render first frame '
    '(cacheKey=$cacheKey, exists=${adapter != null}, disposed=${adapter?.isDisposed}, '
    'initialized=${value?.isInitialized}, firstFrame=${value?.hasRenderedFirstFrame}, '
    'feed=${readSurfaceProbe('feed')}, videoPlayback=${readSurfaceProbe('videoPlayback')}).',
  );
}

Future<void> waitForPlayerPositionAdvanced(
  WidgetTester tester, {
  required String cacheKey,
  required String label,
  required Duration minimumAdvance,
  Duration timeout = const Duration(seconds: 8),
  Duration step = const Duration(milliseconds: 200),
}) async {
  final maxTicks = timeout.inMilliseconds ~/ step.inMilliseconds;
  Duration? baseline;

  for (var i = 0; i < maxTicks; i++) {
    await tester.pump(step);
    final adapter = _adapterForCandidates(
      _resolvePlaybackCacheKeyCandidates(cacheKey),
    );
    final value = adapter?.value;
    if (adapter == null ||
        adapter.isDisposed ||
        value == null ||
        !value.isInitialized ||
        !value.hasRenderedFirstFrame) {
      continue;
    }

    if (!value.isPlaying && !value.isBuffering && !value.isCompleted) {
      await adapter.play();
      await tester.pump(const Duration(milliseconds: 220));
    }

    final position = value.position;
    baseline ??= position > Duration.zero ? position : null;
    if (baseline == null) {
      continue;
    }

    final nearEnd = value.duration > Duration.zero &&
        position >= value.duration - const Duration(milliseconds: 250);
    if (position - baseline >= minimumAdvance || value.isCompleted || nearEnd) {
      return;
    }
  }

  final adapter = _adapterForCandidates(_resolvePlaybackCacheKeyCandidates(
    cacheKey,
  ));
  final value = adapter?.value;
  throw TestFailure(
    '$label did not advance playback '
    '(cacheKey=$cacheKey, exists=${adapter != null}, disposed=${adapter?.isDisposed}, '
    'initialized=${value?.isInitialized}, firstFrame=${value?.hasRenderedFirstFrame}, '
    'playing=${value?.isPlaying}, position=${value?.position}, duration=${value?.duration}, '
    'feed=${readSurfaceProbe('feed')}, videoPlayback=${readSurfaceProbe('videoPlayback')}).',
  );
}

List<String> _resolvePlaybackCacheKeyCandidates(String cacheKey) {
  final candidates = <String>{cacheKey};
  final probe = readIntegrationProbe();
  final playback = Map<String, dynamic>.from(
    (probe['videoPlayback'] as Map?)?.cast<String, dynamic>() ??
        const <String, dynamic>{},
  );

  final current = (playback['currentPlayingDocID'] as String?)?.trim() ?? '';
  if (_matchesPlaybackKey(cacheKey, current)) {
    candidates.add(current);
  }

  final registered = (playback['registeredHandleKeys'] as List?)
          ?.map((item) => item?.toString().trim() ?? '')
          .where((item) => item.isNotEmpty)
          .toList() ??
      const <String>[];
  for (final key in registered) {
    if (_matchesPlaybackKey(cacheKey, key)) {
      candidates.add(key);
    }
  }

  return candidates.toList(growable: false);
}

bool _matchesPlaybackKey(String cacheKey, String candidate) {
  if (candidate.isEmpty) return false;
  if (candidate == cacheKey) return true;
  if (candidate.startsWith('${cacheKey}_')) return true;
  return _stripPlaybackNamespace(candidate) == _stripPlaybackNamespace(cacheKey);
}

String _stripPlaybackNamespace(String value) {
  final colonIndex = value.indexOf(':');
  if (colonIndex <= 0 || colonIndex >= value.length - 1) {
    return value;
  }
  return value.substring(colonIndex + 1);
}

HLSVideoAdapter? _adapterForCandidates(List<String> candidates) {
  for (final candidate in candidates) {
    final adapter =
        ensureGlobalVideoAdapterPool().adapterForTesting(candidate);
    if (adapter != null) {
      return adapter;
    }
  }
  return null;
}
