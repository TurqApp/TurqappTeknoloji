import 'package:flutter_test/flutter_test.dart';
import 'package:turqappv2/Core/Services/integration_test_keys.dart';
import 'package:turqappv2/Modules/Short/short_controller.dart';

import '../bootstrap/test_app_bootstrap.dart';
import 'test_state_probe.dart';

Future<void> swipeToShortIndex(
  WidgetTester tester, {
  required ShortController controller,
  required int targetIndex,
}) async {
  final screen = byItKey(IntegrationTestKeys.screenShort);
  final seenIndices = <int>[];
  final offsets = <double>[300, 360, 420];

  for (var attempt = 0; attempt < 8; attempt++) {
    final currentIndex = _readShortActiveIndex(controller);
    seenIndices.add(currentIndex);
    if (currentIndex == targetIndex) {
      return;
    }

    final direction = targetIndex > currentIndex ? -1.0 : 1.0;
    final distance = offsets[attempt % offsets.length];
    await tester.timedDrag(
      screen,
      Offset(0, direction * distance),
      const Duration(milliseconds: 420),
    );
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 160));
    }
    await expectNoFlutterException(tester);
    if (_readShortActiveIndex(controller) == targetIndex) {
      return;
    }
  }

  final probe = maybeReadSurfaceProbe('short') ?? const <String, dynamic>{};
  final adapter = controller.cache[targetIndex];
  final value = adapter?.value;
  throw TestFailure(
    'short swipe did not settle on target index $targetIndex '
    '(activeIndex=${_readShortActiveIndex(controller)}, '
    'seen=$seenIndices, '
    'probeActiveIndex=${probe['activeIndex']}, '
    'exists=${adapter != null}, disposed=${adapter?.isDisposed}, '
    'initialized=${value?.isInitialized}, firstFrame=${value?.hasRenderedFirstFrame}, '
    'playing=${value?.isPlaying}, position=${value?.position}).',
  );
}

int _readShortActiveIndex(ShortController controller) {
  final probe = maybeReadSurfaceProbe('short');
  final probeIndex = (probe?['activeIndex'] as num?)?.toInt();
  if (probeIndex != null) {
    return probeIndex;
  }
  return controller.lastIndex.value;
}
