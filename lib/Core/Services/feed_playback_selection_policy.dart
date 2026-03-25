import 'dart:core';

import 'package:get/get.dart';

class FeedPlaybackSelectionPolicy {
  static bool shouldIgnoreVisibilityUpdate({
    required double? previousFraction,
    required double visibleFraction,
  }) {
    return GetPlatform.isAndroid &&
        previousFraction != null &&
        (previousFraction - visibleFraction).abs() < 0.12;
  }

  static Duration get evaluationDebounceDuration => GetPlatform.isAndroid
      ? const Duration(milliseconds: 72)
      : const Duration(milliseconds: 40);

  static double get playThreshold => 0.80;

  static double get stopThreshold => GetPlatform.isAndroid ? 0.25 : 0.40;

  static double get secondaryThreshold => GetPlatform.isAndroid ? 0.55 : 0.62;

  static double get hysteresis => GetPlatform.isAndroid ? 0.10 : 0.06;

  static double lingerThreshold({
    required double stopThreshold,
  }) {
    return GetPlatform.isAndroid ? 0.14 : stopThreshold;
  }

  static int resolveCenteredIndex({
    required Map<int, double> visibleFractions,
    required int currentIndex,
    required int? lastCenteredIndex,
    required int itemCount,
    required bool Function(int index) canAutoplayIndex,
    required double stopThreshold,
  }) {
    if (itemCount <= 0) return -1;

    var bestIndex = -1;
    var bestFraction = 0.0;
    var fallbackIndex = -1;
    var fallbackFraction = 0.0;

    visibleFractions.forEach((index, fraction) {
      if (index < 0 || index >= itemCount) return;
      if (!canAutoplayIndex(index)) return;
      if (fraction > fallbackFraction) {
        fallbackFraction = fraction;
        fallbackIndex = index;
      }
      if (fraction < playThreshold) return;
      if (fraction > bestFraction) {
        bestFraction = fraction;
        bestIndex = index;
      }
    });

    if (bestIndex >= 0) {
      final currentFraction =
          currentIndex >= 0 ? (visibleFractions[currentIndex] ?? 0.0) : 0.0;
      final shouldSwitch = currentIndex == -1 ||
          currentIndex == bestIndex ||
          currentFraction < playThreshold ||
          bestFraction >= currentFraction + hysteresis;
      return shouldSwitch ? bestIndex : currentIndex;
    }

    if (fallbackIndex >= 0 && fallbackFraction >= secondaryThreshold) {
      return fallbackIndex;
    }

    if (currentIndex >= 0) {
      final currentFraction = visibleFractions[currentIndex] ?? 0.0;
      if (currentFraction < lingerThreshold(stopThreshold: stopThreshold)) {
        if (lastCenteredIndex != null &&
            lastCenteredIndex >= 0 &&
            lastCenteredIndex < itemCount &&
            canAutoplayIndex(lastCenteredIndex)) {
          return lastCenteredIndex;
        }
        if (currentIndex < itemCount && canAutoplayIndex(currentIndex)) {
          return currentIndex;
        }
        final anyVisiblePlayable = visibleFractions.entries
            .where((entry) =>
                entry.key >= 0 &&
                entry.key < itemCount &&
                canAutoplayIndex(entry.key))
            .map((entry) => entry.key)
            .cast<int?>()
            .firstWhere((entry) => entry != null, orElse: () => null);
        if (anyVisiblePlayable != null) {
          return anyVisiblePlayable;
        }
        final firstPlayable = _findFirstPlayableIndex(
          itemCount: itemCount,
          canAutoplayIndex: canAutoplayIndex,
        );
        return firstPlayable >= 0 ? firstPlayable : -1;
      }
      return currentIndex;
    }

    if (lastCenteredIndex != null &&
        lastCenteredIndex >= 0 &&
        lastCenteredIndex < itemCount &&
        canAutoplayIndex(lastCenteredIndex)) {
      return lastCenteredIndex;
    }

    return -1;
  }

  static int _findFirstPlayableIndex({
    required int itemCount,
    required bool Function(int index) canAutoplayIndex,
  }) {
    for (int index = 0; index < itemCount; index++) {
      if (canAutoplayIndex(index)) {
        return index;
      }
    }
    return -1;
  }
}
