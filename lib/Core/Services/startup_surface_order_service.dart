import 'dart:math';

final int _startupSurfaceOrderSeed = DateTime.now().millisecondsSinceEpoch;

List<T> reorderForStartupSurface<T>(
  List<T> items, {
  required String surfaceKey,
  int maxShuffleWindow = 20,
}) {
  if (items.length < 2 || maxShuffleWindow < 2) {
    return items.toList(growable: false);
  }

  final normalized = items.toList(growable: false);
  final headCount = min(maxShuffleWindow, normalized.length);
  if (headCount < 2) {
    return normalized;
  }

  final originalHead = normalized.take(headCount).toList(growable: false);
  final shuffledHead = originalHead.toList(growable: true)
    ..shuffle(Random(Object.hash(surfaceKey, _startupSurfaceOrderSeed)));

  var changed = false;
  for (int i = 0; i < originalHead.length; i++) {
    if (!identical(originalHead[i], shuffledHead[i])) {
      changed = true;
      break;
    }
  }

  if (!changed) {
    final shift = (_startupSurfaceOrderSeed % headCount).abs();
    final effectiveShift = shift == 0 ? 1 : shift;
    shuffledHead
      ..clear()
      ..addAll(originalHead.skip(effectiveShift))
      ..addAll(originalHead.take(effectiveShift));
  }

  return <T>[
    ...shuffledHead,
    ...normalized.skip(headCount),
  ];
}
