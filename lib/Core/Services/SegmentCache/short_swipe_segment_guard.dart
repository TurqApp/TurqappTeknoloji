import 'package:flutter/foundation.dart';

@immutable
class ShortSwipeSegmentBoundary {
  const ShortSwipeSegmentBoundary({
    required this.docId,
    required this.page,
    required this.reason,
    required this.recordedAt,
    required this.positionMs,
    required this.durationMs,
    required this.progress,
    required this.boundarySegmentOrdinal,
    required this.cachedSegmentCount,
    required this.cachedAfterBoundaryCount,
    required this.maxCachedSegmentOrdinal,
    required this.totalSegmentCount,
  });

  final String docId;
  final int page;
  final String reason;
  final DateTime recordedAt;
  final int positionMs;
  final int durationMs;
  final double progress;
  final int? boundarySegmentOrdinal;
  final int cachedSegmentCount;
  final int cachedAfterBoundaryCount;
  final int? maxCachedSegmentOrdinal;
  final int totalSegmentCount;
}

class ShortSwipeSegmentGuard {
  ShortSwipeSegmentGuard._();

  static final Map<String, ShortSwipeSegmentBoundary> _boundaries =
      <String, ShortSwipeSegmentBoundary>{};

  static const int _maxBoundaries = 160;
  static const Duration _boundaryTtl = Duration(minutes: 30);

  static void recordSwipeAway({
    required String docId,
    required int page,
    required String reason,
    required Duration position,
    required Duration duration,
    required double progress,
    required int? boundarySegmentOrdinal,
    required int cachedSegmentCount,
    required int cachedAfterBoundaryCount,
    required int? maxCachedSegmentOrdinal,
    required int totalSegmentCount,
  }) {
    final normalizedDocId = docId.trim();
    if (normalizedDocId.isEmpty) return;
    final now = DateTime.now();
    _prune(now);
    final boundary = ShortSwipeSegmentBoundary(
      docId: normalizedDocId,
      page: page,
      reason: reason,
      recordedAt: now,
      positionMs: position.inMilliseconds,
      durationMs: duration.inMilliseconds,
      progress: progress.clamp(0.0, 1.0),
      boundarySegmentOrdinal: boundarySegmentOrdinal,
      cachedSegmentCount: cachedSegmentCount,
      cachedAfterBoundaryCount: cachedAfterBoundaryCount,
      maxCachedSegmentOrdinal: maxCachedSegmentOrdinal,
      totalSegmentCount: totalSegmentCount,
    );
    _boundaries[normalizedDocId] = boundary;
    if (kDebugMode) {
      debugPrint(
        '[ShortSwipeSegmentGuard] status=swipe_boundary '
        'doc=${_shortDoc(normalizedDocId)} page=$page reason=$reason '
        'posMs=${boundary.positionMs} durMs=${boundary.durationMs} '
        'progress=${boundary.progress.toStringAsFixed(3)} '
        'boundarySegment=${boundary.boundarySegmentOrdinal ?? '?'} '
        'cachedSegments=$cachedSegmentCount '
        'cachedAfterBoundary=$cachedAfterBoundaryCount '
        'maxCachedSegment=${maxCachedSegmentOrdinal ?? '?'} '
        'totalSegments=$totalSegmentCount',
      );
    }
  }

  static void clearForActiveDoc({
    required String docId,
    required String reason,
  }) {
    final normalizedDocId = docId.trim();
    if (normalizedDocId.isEmpty) return;
    final removed = _boundaries.remove(normalizedDocId);
    if (removed == null || !kDebugMode) return;
    debugPrint(
      '[ShortSwipeSegmentGuard] status=boundary_clear '
      'doc=${_shortDoc(normalizedDocId)} page=${removed.page} '
      'reason=$reason boundarySegment=${removed.boundarySegmentOrdinal ?? '?'}',
    );
  }

  static void recordPrefetchDispatch({
    required String docId,
    required String segmentKey,
    required int? segmentOrdinal,
    required String cacheOrigin,
    required int queueLength,
    required int activeDownloads,
  }) {
    _recordSegmentActivity(
      phase: 'dispatch',
      docId: docId,
      segmentKey: segmentKey,
      segmentOrdinal: segmentOrdinal,
      cacheOrigin: cacheOrigin,
      bytes: null,
      queueLength: queueLength,
      activeDownloads: activeDownloads,
    );
  }

  static void recordPrefetchWrite({
    required String docId,
    required String segmentKey,
    required int? segmentOrdinal,
    required String cacheOrigin,
    required int bytes,
    required int queueLength,
    required int activeDownloads,
  }) {
    _recordSegmentActivity(
      phase: 'write',
      docId: docId,
      segmentKey: segmentKey,
      segmentOrdinal: segmentOrdinal,
      cacheOrigin: cacheOrigin,
      bytes: bytes,
      queueLength: queueLength,
      activeDownloads: activeDownloads,
    );
  }

  static bool shouldDropPrefetchWriteAfterSwipe({
    required String docId,
    required String segmentKey,
    required int? segmentOrdinal,
    required String cacheOrigin,
    required int bytes,
    required int queueLength,
    required int activeDownloads,
  }) {
    final normalizedDocId = docId.trim();
    if (normalizedDocId.isEmpty) return false;
    final now = DateTime.now();
    _prune(now);
    final boundary = _boundaries[normalizedDocId];
    if (boundary == null) return false;
    final boundaryOrdinal = boundary.boundarySegmentOrdinal;
    final shouldDrop = segmentOrdinal != null &&
        boundaryOrdinal != null &&
        segmentOrdinal > boundaryOrdinal;
    if (!shouldDrop) return false;
    final ageMs = now.difference(boundary.recordedAt).inMilliseconds;
    if (kDebugMode) {
      debugPrint(
        '[ShortSwipeSegmentGuard] status=drop_after_swipe '
        'doc=${_shortDoc(normalizedDocId)} page=${boundary.page} '
        'segment=$segmentKey segmentOrdinal=$segmentOrdinal '
        'boundarySegment=$boundaryOrdinal '
        'cachedAtSwipe=${boundary.cachedSegmentCount} '
        'cachedAfterBoundaryAtSwipe=${boundary.cachedAfterBoundaryCount} '
        'maxCachedAtSwipe=${boundary.maxCachedSegmentOrdinal ?? '?'} '
        'totalSegments=${boundary.totalSegmentCount} '
        'origin=$cacheOrigin queue=$queueLength active=$activeDownloads '
        'bytes=$bytes ageMs=$ageMs',
      );
    }
    return true;
  }

  static bool shouldBlockPrefetchDispatchAfterSwipe({
    required String docId,
    required String segmentKey,
    required int? segmentOrdinal,
    required String cacheOrigin,
    required int queueLength,
    required int activeDownloads,
  }) {
    final normalizedDocId = docId.trim();
    if (normalizedDocId.isEmpty) return false;
    final now = DateTime.now();
    _prune(now);
    final boundary = _boundaries[normalizedDocId];
    if (boundary == null) return false;
    final boundaryOrdinal = boundary.boundarySegmentOrdinal;
    final shouldBlock = segmentOrdinal != null &&
        boundaryOrdinal != null &&
        segmentOrdinal > boundaryOrdinal;
    if (!shouldBlock) return false;
    final ageMs = now.difference(boundary.recordedAt).inMilliseconds;
    if (kDebugMode) {
      debugPrint(
        '[ShortSwipeSegmentGuard] status=block_dispatch_after_swipe '
        'doc=${_shortDoc(normalizedDocId)} page=${boundary.page} '
        'segment=$segmentKey segmentOrdinal=$segmentOrdinal '
        'boundarySegment=$boundaryOrdinal '
        'cachedAtSwipe=${boundary.cachedSegmentCount} '
        'cachedAfterBoundaryAtSwipe=${boundary.cachedAfterBoundaryCount} '
        'maxCachedAtSwipe=${boundary.maxCachedSegmentOrdinal ?? '?'} '
        'totalSegments=${boundary.totalSegmentCount} '
        'origin=$cacheOrigin queue=$queueLength active=$activeDownloads '
        'ageMs=$ageMs',
      );
    }
    return true;
  }

  static void _recordSegmentActivity({
    required String phase,
    required String docId,
    required String segmentKey,
    required int? segmentOrdinal,
    required String cacheOrigin,
    required int? bytes,
    required int queueLength,
    required int activeDownloads,
  }) {
    if (!kDebugMode) return;
    final normalizedDocId = docId.trim();
    if (normalizedDocId.isEmpty) return;
    final now = DateTime.now();
    _prune(now);
    final boundary = _boundaries[normalizedDocId];
    if (boundary == null) return;
    final boundaryOrdinal = boundary.boundarySegmentOrdinal;
    final violates = segmentOrdinal != null &&
        boundaryOrdinal != null &&
        segmentOrdinal > boundaryOrdinal;
    final ageMs = now.difference(boundary.recordedAt).inMilliseconds;
    debugPrint(
      '[ShortSwipeSegmentGuard] '
      'status=${violates ? 'violation_$phase' : '${phase}_after_swipe'} '
      'doc=${_shortDoc(normalizedDocId)} page=${boundary.page} '
      'segment=$segmentKey segmentOrdinal=${segmentOrdinal ?? '?'} '
      'boundarySegment=${boundaryOrdinal ?? '?'} '
      'cachedAtSwipe=${boundary.cachedSegmentCount} '
      'cachedAfterBoundaryAtSwipe=${boundary.cachedAfterBoundaryCount} '
      'maxCachedAtSwipe=${boundary.maxCachedSegmentOrdinal ?? '?'} '
      'totalSegments=${boundary.totalSegmentCount} '
      'origin=$cacheOrigin queue=$queueLength active=$activeDownloads '
      'bytes=${bytes ?? 0} ageMs=$ageMs',
    );
  }

  static int? estimateBoundarySegment({
    required Duration position,
    required Duration duration,
    required int totalSegmentCount,
  }) {
    if (totalSegmentCount <= 0) return null;
    if (duration <= Duration.zero) {
      return 1;
    }
    final progress =
        position.inMilliseconds / duration.inMilliseconds.clamp(1, 1 << 31);
    final ordinal = (progress * totalSegmentCount).floor() + 1;
    return ordinal.clamp(1, totalSegmentCount);
  }

  static int? segmentOrdinalFromKey(String segmentKey) {
    final fileName = segmentKey.split('/').last;
    final match = RegExp(r'(\d+)(?=\D*$)').firstMatch(fileName);
    if (match == null) return null;
    final parsed = int.tryParse(match.group(1)!);
    if (parsed == null) return null;
    return parsed + 1;
  }

  static void _prune(DateTime now) {
    _boundaries.removeWhere(
      (_, boundary) => now.difference(boundary.recordedAt) > _boundaryTtl,
    );
    if (_boundaries.length <= _maxBoundaries) return;
    final sorted = _boundaries.values.toList(growable: false)
      ..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));
    final removeCount = _boundaries.length - _maxBoundaries;
    for (final boundary in sorted.take(removeCount)) {
      _boundaries.remove(boundary.docId);
    }
  }

  static String _shortDoc(String docId) {
    if (docId.length <= 12) return docId;
    return '${docId.substring(0, 6)}...${docId.substring(docId.length - 4)}';
  }
}
