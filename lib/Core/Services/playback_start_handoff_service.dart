import 'dart:async';

import 'package:flutter/foundation.dart';

typedef PlaybackStartHandoffCallback = FutureOr<void> Function();

class PlaybackStartHandoffService {
  PlaybackStartHandoffService._();

  static final PlaybackStartHandoffService instance =
      PlaybackStartHandoffService._();

  static const Duration _dedupeWindow = Duration(seconds: 8);
  static const Duration _retentionWindow = Duration(seconds: 30);

  final Map<String, DateTime> _lastHandoffAtByKey = <String, DateTime>{};

  void notifyPlaybackStarted({
    required String surface,
    required String anchorKey,
    required PlaybackStartHandoffCallback warmNext,
  }) {
    final normalizedSurface =
        surface.trim().isEmpty ? 'unknown' : surface.trim();
    final normalizedAnchorKey = anchorKey.trim();
    if (normalizedAnchorKey.isEmpty) return;

    final now = DateTime.now();
    final key = '$normalizedSurface::$normalizedAnchorKey';
    final lastAt = _lastHandoffAtByKey[key];
    if (lastAt != null && now.difference(lastAt) < _dedupeWindow) {
      return;
    }
    _lastHandoffAtByKey[key] = now;
    if (_lastHandoffAtByKey.length > 256) {
      _lastHandoffAtByKey.removeWhere(
        (_, handoffAt) => now.difference(handoffAt) > _retentionWindow,
      );
    }

    debugPrint(
      '[PlaybackStartHandoff] status=scheduled surface=$normalizedSurface '
      'anchor=$normalizedAnchorKey',
    );
    scheduleMicrotask(() {
      unawaited(() async {
        try {
          await warmNext();
        } catch (error) {
          debugPrint(
            '[PlaybackStartHandoff] status=failed surface=$normalizedSurface '
            'anchor=$normalizedAnchorKey error=$error',
          );
        }
      }());
    });
  }
}
