import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turqappv2/Core/Services/integration_test_keys.dart';
import 'package:turqappv2/Modules/Short/short_controller.dart';
import 'package:turqappv2/hls_player/hls_video_adapter.dart';

import '../core/bootstrap/test_app_bootstrap.dart';
import '../core/helpers/short_swipe_helpers.dart';
import '../core/helpers/smoke_artifact_collector.dart';

void main() {
  ensureIntegrationBinding();

  testWidgets(
    'Short active video stays advancing across HLS segment boundaries',
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
          'short_segment_boundary_hold',
          tester,
          () async {
            await launchTurqApp(tester);
            await tapItKey(
              tester,
              IntegrationTestKeys.navShort,
              settlePumps: 12,
            );
            expect(byItKey(IntegrationTestKeys.screenShort), findsOneWidget);

            final controller = ShortController.ensure();
            final target = await _findPlayableLongShort(
              tester,
              controller: controller,
            );
            await _assertSegmentBoundariesStaySmooth(
              tester,
              controller: controller,
              index: target.index,
              adapter: target.adapter,
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

const _segmentBoundaries = <Duration>[
  Duration(seconds: 2),
  Duration(seconds: 8),
  Duration(seconds: 14),
  Duration(seconds: 20),
  Duration(seconds: 26),
  Duration(seconds: 32),
];

class _PlayableShortTarget {
  const _PlayableShortTarget({
    required this.index,
    required this.adapter,
  });

  final int index;
  final HLSVideoAdapter adapter;
}

Future<_PlayableShortTarget> _findPlayableLongShort(
  WidgetTester tester, {
  required ShortController controller,
}) async {
  const minimumDuration = Duration(seconds: 34);
  final inspected = <String>[];

  for (var index = 0; index < 8; index++) {
    if (index > 0) {
      await swipeToShortIndex(
        tester,
        controller: controller,
        targetIndex: index,
      );
    }

    final adapter = await _waitForPlayableFrame(
      tester,
      controller: controller,
      index: index,
      label: 'short segment boundary candidate $index',
    );
    final duration = adapter.value.duration;
    final docId = index < controller.shorts.length
        ? controller.shorts[index].docID
        : '<missing>';
    inspected.add('idx=$index doc=$docId duration=$duration');
    debugPrint(
      '[short-segment-boundary] candidate idx=$index doc=$docId '
      'duration=$duration',
    );

    if (duration >= minimumDuration) {
      return _PlayableShortTarget(index: index, adapter: adapter);
    }
  }

  throw TestFailure(
    'No short video long enough to cover segment boundary smoke '
    '(${minimumDuration.inSeconds}s). inspected=${inspected.join(' | ')}',
  );
}

Future<HLSVideoAdapter> _waitForPlayableFrame(
  WidgetTester tester, {
  required ShortController controller,
  required int index,
  required String label,
}) async {
  const timeout = Duration(seconds: 10);
  const step = Duration(milliseconds: 200);
  final maxTicks = timeout.inMilliseconds ~/ step.inMilliseconds;

  for (var i = 0; i < maxTicks; i++) {
    await tester.pump(step);
    final adapter = controller.cache[index];
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

  final adapter = controller.cache[index];
  final value = adapter?.value;
  throw TestFailure(
    '$label did not reach playable frame state '
    '(exists=${adapter != null}, disposed=${adapter?.isDisposed}, '
    'initialized=${value?.isInitialized}, firstFrame=${value?.hasRenderedFirstFrame}, '
    'playing=${value?.isPlaying}, position=${value?.position}).',
  );
}

Future<void> _assertSegmentBoundariesStaySmooth(
  WidgetTester tester, {
  required ShortController controller,
  required int index,
  required HLSVideoAdapter adapter,
}) async {
  const step = Duration(milliseconds: 200);
  const maxAllowedStall = Duration(milliseconds: 1400);
  const boundaryWindow = Duration(milliseconds: 1200);
  final targetPosition =
      _segmentBoundaries.last + const Duration(milliseconds: 1400);
  var previousPosition = adapter.value.position;
  var stalledFor = Duration.zero;
  final crossed = <Duration>{};

  if (!adapter.value.isPlaying) {
    await adapter.play();
  }

  debugPrint(
    '[short-segment-boundary] hold-start idx=$index '
    'doc=${controller.shorts[index].docID} position=${adapter.value.position} '
    'duration=${adapter.value.duration} usesLocalProxy=${adapter.usesLocalProxy}',
  );

  for (var elapsed = Duration.zero;
      elapsed <= const Duration(seconds: 40);
      elapsed += step) {
    await tester.pump(step);
    final current = adapter.value;
    final position = current.position;
    final duration = current.duration;

    if (current.isCompleted ||
        (duration > Duration.zero &&
            position >= duration - const Duration(milliseconds: 250))) {
      throw TestFailure(
        'Segment boundary smoke ended before ${targetPosition.inSeconds}s '
        '(idx=$index, position=$position, duration=$duration).',
      );
    }

    for (final boundary in _segmentBoundaries) {
      if (!crossed.contains(boundary) &&
          previousPosition < boundary &&
          position >= boundary) {
        crossed.add(boundary);
        final muted = await adapter.isMutedNative();
        debugPrint(
          '[short-segment-boundary] crossed boundary=${boundary.inSeconds}s '
          'idx=$index position=$position playing=${current.isPlaying} '
          'buffering=${current.isBuffering} muted=$muted '
          'duration=$duration',
        );
        if (muted) {
          throw TestFailure(
            'Short became muted at segment boundary ${boundary.inSeconds}s '
            '(idx=$index, position=$position).',
          );
        }
      }
    }

    final advanced =
        position > previousPosition + const Duration(milliseconds: 60);
    if (advanced) {
      stalledFor = Duration.zero;
    } else {
      stalledFor += step;
    }

    final nearBoundary = _segmentBoundaries.any(
      (boundary) => (position - boundary).abs() <= boundaryWindow,
    );
    if (nearBoundary && stalledFor >= maxAllowedStall) {
      throw TestFailure(
        'Short stalled around HLS segment boundary '
        '(idx=$index, position=$position, previous=$previousPosition, '
        'stalledFor=$stalledFor, playing=${current.isPlaying}, '
        'buffering=${current.isBuffering}, duration=$duration).',
      );
    }

    previousPosition = position;
    if (position >= targetPosition) break;
  }

  final missing = _segmentBoundaries
      .where((boundary) => !crossed.contains(boundary))
      .map((boundary) => '${boundary.inSeconds}s')
      .toList(growable: false);
  if (missing.isNotEmpty) {
    throw TestFailure(
      'Segment boundary smoke did not cross all target boundaries '
      '(idx=$index, position=${adapter.value.position}, '
      'duration=${adapter.value.duration}, missing=${missing.join(', ')}).',
    );
  }

  debugPrint(
    '[short-segment-boundary] hold-pass idx=$index '
    'position=${adapter.value.position} duration=${adapter.value.duration}',
  );
}
