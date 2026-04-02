import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:turqappv2/Core/Repositories/config_repository.dart';

class HlsSegmentPolicy {
  static const int _defaultFirstSegmentSeconds = 2;
  static const int _defaultNextSegmentSeconds = 6;
  static const double _watchIntentLeadSeconds = 2.0;
  static const Duration _configTtl = Duration(minutes: 30);

  static int _firstSegmentSeconds = _defaultFirstSegmentSeconds;
  static int _nextSegmentSeconds = _defaultNextSegmentSeconds;
  static Future<void>? _refreshFuture;

  static int get firstSegmentSeconds => _firstSegmentSeconds;

  static int get nextSegmentSeconds => _nextSegmentSeconds;

  static double get watchIntentThresholdSeconds =>
      firstSegmentSeconds + _watchIntentLeadSeconds;

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
    final separatorIndex = normalized.indexOf(':');
    if (separatorIndex < 0) return normalized;
    final docId = normalized.substring(separatorIndex + 1).trim();
    return docId.isEmpty ? null : docId;
  }

  static int estimateCurrentSegment({
    required double positionSeconds,
    required int totalSegments,
  }) {
    if (totalSegments <= 1) return 1;
    final position = positionSeconds.isFinite
        ? positionSeconds.clamp(0.0, double.infinity)
        : 0.0;
    final first = firstSegmentSeconds.toDouble();
    final next = nextSegmentSeconds.toDouble();
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
    if (totalSegments <= 1) return 1;
    final normalized = progress.clamp(0.0, 1.0);
    final approximateTotalSeconds =
        firstSegmentSeconds + (nextSegmentSeconds * (totalSegments - 1));
    return estimateCurrentSegment(
      positionSeconds: normalized * approximateTotalSeconds,
      totalSegments: totalSegments,
    );
  }

  static bool hasReachedWatchIntent(double positionSeconds) {
    if (!positionSeconds.isFinite) return false;
    return positionSeconds >= watchIntentThresholdSeconds;
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
