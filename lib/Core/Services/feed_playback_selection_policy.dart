import 'dart:core';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

class FeedPlaybackSelectionPolicy {
  static bool get _isAndroidPlatform =>
      GetPlatform.isAndroid || defaultTargetPlatform == TargetPlatform.android;

  static bool shouldIgnoreVisibilityUpdate({
    required double? previousFraction,
    required double visibleFraction,
  }) {
    return _isAndroidPlatform &&
        previousFraction != null &&
        (previousFraction - visibleFraction).abs() < 0.08;
  }

  static Duration get evaluationDebounceDuration => _isAndroidPlatform
      ? const Duration(milliseconds: 48)
      : const Duration(milliseconds: 16);

  static double get playThreshold => _isAndroidPlatform ? 0.72 : 0.72;

  static double get stopThreshold => _isAndroidPlatform ? 0.25 : 0.25;

  static double get secondaryThreshold => _isAndroidPlatform ? 0.50 : 0.50;

  static double get hysteresis => _isAndroidPlatform ? 0.08 : 0.08;

  static double get switchRetentionThreshold =>
      _isAndroidPlatform ? 0.52 : 0.52;

  static double get switchDominanceMargin => _isAndroidPlatform ? 0.12 : 0.12;

  static Duration get scrollSettleReassertDuration => _isAndroidPlatform
      ? const Duration(milliseconds: 140)
      : const Duration(milliseconds: 100);

  static Duration get playbackTargetStickinessDuration => _isAndroidPlatform
      ? const Duration(milliseconds: 220)
      : const Duration(milliseconds: 180);

  static Duration get pendingPlaybackTargetRetentionDuration =>
      _isAndroidPlatform ? const Duration(milliseconds: 220) : Duration.zero;

  static bool shouldPlayCenteredItem({
    required bool isCentered,
    bool isSurfacePlaybackSuspended = false,
    bool isOverlayBlockingPlayback = false,
  }) {
    return isCentered &&
        !isSurfacePlaybackSuspended &&
        !isOverlayBlockingPlayback;
  }

  static double lingerThreshold({
    required double stopThreshold,
  }) {
    return _isAndroidPlatform ? 0.12 : stopThreshold;
  }

  static bool shouldRetainRecentlyActivatedTarget({
    required DateTime? lastCommandAt,
    required String? lastCommandDocId,
    required String currentDocId,
    required bool isCurrentTargetActive,
    required double currentFraction,
    required double stopThreshold,
  }) {
    if (!_isAndroidPlatform) return false;
    if (lastCommandAt == null) return false;
    if (lastCommandDocId == null || lastCommandDocId != currentDocId) {
      return false;
    }
    if (currentFraction < stopThreshold) return false;
    final elapsed = DateTime.now().difference(lastCommandAt);
    if (isCurrentTargetActive) {
      return elapsed < playbackTargetStickinessDuration;
    }
    if (currentFraction < switchRetentionThreshold) return false;
    return elapsed < pendingPlaybackTargetRetentionDuration;
  }

  static int resolveCenteredIndex({
    required Map<int, double> visibleFractions,
    required int currentIndex,
    required int? lastCenteredIndex,
    required int itemCount,
    required bool Function(int index) canAutoplayIndex,
    required double stopThreshold,
    bool preferDominantVisibleIndexWhenNonPlayable = false,
  }) {
    if (itemCount <= 0) return -1;

    var bestIndex = -1;
    var bestFraction = 0.0;
    var fallbackIndex = -1;
    var fallbackFraction = 0.0;
    var strongestOverallIndex = -1;
    var strongestOverallFraction = 0.0;

    visibleFractions.forEach((index, fraction) {
      if (index < 0 || index >= itemCount) return;
      if (fraction > strongestOverallFraction) {
        strongestOverallFraction = fraction;
        strongestOverallIndex = index;
      }
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
      final shouldRetainCurrentTarget = currentIndex >= 0 &&
          currentIndex != bestIndex &&
          canAutoplayIndex(currentIndex) &&
          currentFraction >= switchRetentionThreshold &&
          bestFraction < currentFraction + switchDominanceMargin;
      if (shouldRetainCurrentTarget) {
        return currentIndex;
      }
      final shouldSwitch = currentIndex == -1 ||
          currentIndex == bestIndex ||
          currentFraction < playThreshold ||
          bestFraction >= currentFraction + hysteresis;
      return shouldSwitch ? bestIndex : currentIndex;
    }

    final dominantVisibleIndex = strongestOverallIndex;
    final dominantVisibleIsNonPlayable = dominantVisibleIndex >= 0 &&
        dominantVisibleIndex < itemCount &&
        !canAutoplayIndex(dominantVisibleIndex) &&
        strongestOverallFraction >= playThreshold;
    if (preferDominantVisibleIndexWhenNonPlayable &&
        strongestOverallIndex >= 0 &&
        strongestOverallIndex < itemCount &&
        !canAutoplayIndex(strongestOverallIndex) &&
        strongestOverallFraction >= secondaryThreshold) {
      return strongestOverallIndex;
    }
    if (dominantVisibleIsNonPlayable) {
      return -1;
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
