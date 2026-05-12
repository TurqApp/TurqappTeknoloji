import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:turqappv2/Core/Repositories/config_repository.dart';

class HlsSegmentPolicy {
  static const int _defaultFirstSegmentSeconds = 2;
  static const int _defaultNextSegmentSeconds = 6;
  static const int storyFirstSegmentSeconds = 2;
  static const int storyNextSegmentSeconds = 3;
  static const Duration _configTtl = Duration(minutes: 30);
  static const int playbackWarmMaxSegmentOrdinal = 2;

  static int _firstSegmentSeconds = _defaultFirstSegmentSeconds;
  static int _nextSegmentSeconds = _defaultNextSegmentSeconds;
  static Future<void>? _refreshFuture;

  static int get firstSegmentSeconds => _firstSegmentSeconds;

  static int get nextSegmentSeconds => _nextSegmentSeconds;

  static double bufferSecondsForSegmentOrdinal(
    int segmentOrdinal, {
    double nextSegmentFraction = 1.0,
  }) {
    if (segmentOrdinal <= 1) return firstSegmentSeconds.toDouble();
    final clampedFraction = nextSegmentFraction.clamp(0.0, 1.0);
    return firstSegmentSeconds +
        ((segmentOrdinal - 1) * nextSegmentSeconds * clampedFraction);
  }

  static Future<void> refresh({bool forceRefresh = false}) {
    final inFlight = _refreshFuture;
    if (inFlight != null && !forceRefresh) {
      return inFlight;
    }

    final future = _refreshImpl(forceRefresh: forceRefresh);
    _refreshFuture = future;
    return future.whenComplete(() {
      if (identical(_refreshFuture, future)) {
        _refreshFuture = null;
      }
    });
  }

  static Future<void> _refreshImpl({required bool forceRefresh}) async {
    try {
      final data = await ensureConfigRepository().getAdminConfigDoc(
        'hlsSegment',
        preferCache: !forceRefresh,
        forceRefresh: forceRefresh,
        ttl: _configTtl,
      );
      if (data == null || data.isEmpty) return;
      _firstSegmentSeconds = _clampSegmentSeconds(
        data['segment1'],
        _defaultFirstSegmentSeconds,
      );
      _nextSegmentSeconds = _clampSegmentSeconds(
        data['segment2'],
        _defaultNextSegmentSeconds,
      );
    } catch (_) {}
  }

  static String? normalizeDocId(String? rawDocId) {
    final normalized = rawDocId?.trim();
    if (normalized == null || normalized.isEmpty) return null;
    const socialPrefixes = <String>[
      'social_post_',
      'social_reshare_',
      'profile_post_',
      'profile_reshare_',
    ];
    for (final prefix in socialPrefixes) {
      if (normalized.startsWith(prefix)) {
        final docId = normalized.substring(prefix.length).trim();
        return docId.isEmpty ? null : docId;
      }
    }
    final separatorIndex = normalized.indexOf(':');
    if (separatorIndex < 0) return normalized;
    final docId = normalized.substring(separatorIndex + 1).trim();
    return docId.isEmpty ? null : docId;
  }

  static int estimateCurrentSegment({
    required double positionSeconds,
    required int totalSegments,
  }) {
    return estimateCurrentSegmentWithDurations(
      positionSeconds: positionSeconds,
      totalSegments: totalSegments,
      firstSegmentSeconds: firstSegmentSeconds,
      nextSegmentSeconds: nextSegmentSeconds,
    );
  }

  static int estimateCurrentSegmentWithDurations({
    required double positionSeconds,
    required int totalSegments,
    required int firstSegmentSeconds,
    required int nextSegmentSeconds,
  }) {
    if (totalSegments <= 1) return 1;
    final position = positionSeconds.isFinite
        ? positionSeconds.clamp(0.0, double.infinity)
        : 0.0;
    final first = (firstSegmentSeconds < 1
            ? _defaultFirstSegmentSeconds
            : firstSegmentSeconds)
        .toDouble();
    final next = (nextSegmentSeconds < 1
            ? _defaultNextSegmentSeconds
            : nextSegmentSeconds)
        .toDouble();
    if (position < first) {
      return 1;
    }
    final segment = 2 + ((position - first) / next).floor();
    return segment.clamp(1, totalSegments);
  }

  static int estimateCurrentSegmentFromProgress({
    required double progress,
    required int totalSegments,
  }) {
    return estimateCurrentSegmentFromProgressWithDurations(
      progress: progress,
      totalSegments: totalSegments,
      firstSegmentSeconds: firstSegmentSeconds,
      nextSegmentSeconds: nextSegmentSeconds,
    );
  }

  static int estimateCurrentSegmentFromProgressWithDurations({
    required double progress,
    required int totalSegments,
    required int firstSegmentSeconds,
    required int nextSegmentSeconds,
  }) {
    if (totalSegments <= 1) return 1;
    final normalized = progress.clamp(0.0, 1.0);
    final first = firstSegmentSeconds < 1
        ? _defaultFirstSegmentSeconds
        : firstSegmentSeconds;
    final next = nextSegmentSeconds < 1
        ? _defaultNextSegmentSeconds
        : nextSegmentSeconds;
    final approximateTotalSeconds = first + (next * (totalSegments - 1));
    return estimateCurrentSegmentWithDurations(
      positionSeconds: normalized * approximateTotalSeconds,
      totalSegments: totalSegments,
      firstSegmentSeconds: first,
      nextSegmentSeconds: next,
    );
  }

  static int _clampSegmentSeconds(dynamic value, int fallback) {
    int? parsed;
    if (value is num) {
      parsed = value.toInt();
    } else if (value is String) {
      parsed =
          int.tryParse(value.trim()) ?? num.tryParse(value.trim())?.toInt();
    }
    final resolved = parsed ?? fallback;
    return resolved < 1 ? fallback : resolved;
  }

  @visibleForTesting
  static void debugSetSegments({
    required int firstSegmentSeconds,
    required int nextSegmentSeconds,
  }) {
    _firstSegmentSeconds = firstSegmentSeconds < 1
        ? _defaultFirstSegmentSeconds
        : firstSegmentSeconds;
    _nextSegmentSeconds = nextSegmentSeconds < 1
        ? _defaultNextSegmentSeconds
        : nextSegmentSeconds;
  }

  @visibleForTesting
  static void debugReset() {
    _firstSegmentSeconds = _defaultFirstSegmentSeconds;
    _nextSegmentSeconds = _defaultNextSegmentSeconds;
    _refreshFuture = null;
  }
}
