import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turqappv2/Ads/admob_kare.dart';
import 'package:turqappv2/Core/Services/integration_test_keys.dart';
import 'package:turqappv2/Modules/Short/short_controller.dart';
import 'package:turqappv2/hls_player/hls_video_adapter.dart';

import '../core/bootstrap/test_app_bootstrap.dart';
import '../core/helpers/short_swipe_helpers.dart';
import '../core/helpers/smoke_artifact_collector.dart';
import '../core/helpers/transient_error_policy.dart';

void main() {
  ensureIntegrationBinding();

  testWidgets(
    'Short ad slot shows Google or TurqApp fallback and keeps organic flow playable',
    (tester) async {
      final originalOnError = installTransientFlutterErrorPolicy();
      try {
        await SmokeArtifactCollector.runScenario(
          'short_google_ads_gate',
          tester,
          () async {
            await launchTurqApp(
              tester,
              relaxFeedFixtureDocRequirement: true,
              primeShortSnapshot: true,
            );
            await tapItKey(
              tester,
              IntegrationTestKeys.navShort,
              settlePumps: 12,
            );
            expect(byItKey(IntegrationTestKeys.screenShort), findsOneWidget);

            final controller = ensureShortController();
            await _ensureShortSurfaceHasItems(
              tester,
              controller: controller,
              minimumCount: 6,
            );

            await _assertPlayableFrame(
              tester,
              controller: controller,
              index: 0,
              label: 'short 0',
            );

            await _warmAdPoolWindow(tester);

            await swipeToShortIndex(
              tester,
              controller: controller,
              targetIndex: 4,
            );
            await _assertPlayableFrame(
              tester,
              controller: controller,
              index: 4,
              label: 'short 4 before ad gate',
            );

            final shortScreen = byItKey(IntegrationTestKeys.screenShort);
            await tester.timedDrag(
              shortScreen,
              const Offset(0, -320),
              const Duration(milliseconds: 420),
            );

            final sawAdPage = await _waitForAdGateDecision(tester);
            expect(
              sawAdPage,
              isTrue,
              reason:
                  'Short should reserve the ad slot and show Google or TurqApp fallback.',
            );
            expect(
              find.byKey(const ValueKey('short-ad-page-1')),
              findsOneWidget,
            );

            await swipeToShortIndex(
              tester,
              controller: controller,
              targetIndex: 5,
            );
            await _assertPlayableFrame(
              tester,
              controller: controller,
              index: 5,
              label: 'short 5 after ad gate',
            );
            expect(
              find.byKey(const ValueKey('short-ad-page-1')),
              findsNothing,
            );
          },
        );
      } finally {
        restoreTransientFlutterErrorPolicy(originalOnError);
      }
    },
    skip: !kRunIntegrationSmoke,
  );
}

Future<void> _ensureShortSurfaceHasItems(
  WidgetTester tester, {
  required ShortController controller,
  required int minimumCount,
}) async {
  const pollStep = Duration(milliseconds: 250);
  const maxAttempts = 3;

  for (var attempt = 0; attempt < maxAttempts; attempt++) {
    final deadline = DateTime.now().add(
      Duration(seconds: attempt == 0 ? 6 : 8),
    );
    while (DateTime.now().isBefore(deadline)) {
      await tester.pump(pollStep);
      final error = tester.takeException();
      if (error != null) {
        final text = error.toString();
        if (!isAllowedNonFatalIntegrationErrorText(text)) {
          throw TestFailure('short ad gate preload exception: $error');
        }
      }
      if (controller.shorts.length >= minimumCount) {
        return;
      }
    }

    if (attempt == maxAttempts - 1) {
      break;
    }

    await controller.prepareStartupSurface(allowBackgroundRefresh: true);
    await controller.refreshShorts();
    await tester.pump(const Duration(milliseconds: 600));
  }

  throw TestFailure(
    'Short surface stayed below $minimumCount items after retries '
    '(count=${controller.shorts.length}, hasMore=${controller.hasMore.value}, '
    'isLoading=${controller.isLoading.value}, isRefreshing=${controller.isRefreshing.value}).',
  );
}

Future<void> _warmAdPoolWindow(WidgetTester tester) async {
  const timeout = Duration(seconds: 8);
  const step = Duration(milliseconds: 250);
  final maxTicks = timeout.inMilliseconds ~/ step.inMilliseconds;
  for (var i = 0; i < maxTicks; i++) {
    await tester.pump(step);
    if (AdmobKare.hasRenderableBanner) {
      return;
    }
  }
}

Future<bool> _waitForAdGateDecision(WidgetTester tester) async {
  const timeout = Duration(seconds: 4);
  const step = Duration(milliseconds: 160);
  final maxTicks = timeout.inMilliseconds ~/ step.inMilliseconds;
  final adPage = find.byKey(const ValueKey('short-ad-page-1'));
  for (var i = 0; i < maxTicks; i++) {
    await tester.pump(step);
    final error = tester.takeException();
    if (error != null) {
      final text = error.toString();
      if (!isAllowedNonFatalIntegrationErrorText(text)) {
        throw TestFailure('short ad gate decision exception: $error');
      }
    }
    if (adPage.evaluate().isNotEmpty) {
      return true;
    }
  }
  return false;
}

Future<HLSVideoAdapter> _assertPlayableFrame(
  WidgetTester tester, {
  required ShortController controller,
  required int index,
  required String label,
}) async {
  const timeout = Duration(seconds: 8);
  const step = Duration(milliseconds: 200);
  final maxTicks = timeout.inMilliseconds ~/ step.inMilliseconds;

  for (var i = 0; i < maxTicks; i++) {
    await tester.pump(step);
    final error = tester.takeException();
    if (error != null) {
      final text = error.toString();
      if (!isAllowedNonFatalIntegrationErrorText(text)) {
        throw TestFailure('$label exception: $error');
      }
    }

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
