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
    final adapter = GlobalVideoAdapterPool.ensure().adapterForTesting(cacheKey);
    if (adapter != null && !adapter.isDisposed) {
      return adapter;
    }
  }

  throw TestFailure(
    '$label did not expose a player adapter (cacheKey=$cacheKey).',
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
    final adapter = GlobalVideoAdapterPool.ensure().adapterForTesting(cacheKey);
    final value = adapter?.value;
    if (adapter != null &&
        !adapter.isDisposed &&
        value != null &&
        value.isInitialized) {
      return adapter;
    }
  }

  final adapter = GlobalVideoAdapterPool.ensure().adapterForTesting(cacheKey);
  throw TestFailure(
    '$label did not reach initialized player state '
    '(cacheKey=$cacheKey, exists=${adapter != null}, disposed=${adapter?.isDisposed}, '
    'initialized=${adapter?.value.isInitialized}).',
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
    final adapter = GlobalVideoAdapterPool.ensure().adapterForTesting(cacheKey);
    final value = adapter?.value;
    if (adapter != null &&
        !adapter.isDisposed &&
        value != null &&
        value.isInitialized &&
        value.hasRenderedFirstFrame) {
      return adapter;
    }
  }

  final adapter = GlobalVideoAdapterPool.ensure().adapterForTesting(cacheKey);
  final value = adapter?.value;
  throw TestFailure(
    '$label did not render first frame '
    '(cacheKey=$cacheKey, exists=${adapter != null}, disposed=${adapter?.isDisposed}, '
    'initialized=${value?.isInitialized}, firstFrame=${value?.hasRenderedFirstFrame}).',
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
    final adapter = GlobalVideoAdapterPool.ensure().adapterForTesting(cacheKey);
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

  final adapter = GlobalVideoAdapterPool.ensure().adapterForTesting(cacheKey);
  final value = adapter?.value;
  throw TestFailure(
    '$label did not advance playback '
    '(cacheKey=$cacheKey, exists=${adapter != null}, disposed=${adapter?.isDisposed}, '
    'initialized=${value?.isInitialized}, firstFrame=${value?.hasRenderedFirstFrame}, '
    'playing=${value?.isPlaying}, position=${value?.position}, duration=${value?.duration}).',
  );
}
