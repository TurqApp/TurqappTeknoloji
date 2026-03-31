/// HLS segment cache data modelleri.
library;

import 'package:turqappv2/Models/posts_model.dart';

enum VideoCacheState {
  uncached,
  fetching,
  partial,
  ready,
  playing,
  watched,
  evictable,
}

class CachedSegment {
  final String segmentUri; // e.g. "720p/segment_0.ts"
  final String diskPath; // absolute path
  final int sizeBytes;
  final DateTime cachedAt;

  CachedSegment({
    required this.segmentUri,
    required this.diskPath,
    required this.sizeBytes,
    required this.cachedAt,
  });

  Map<String, dynamic> toJson() => {
        'segmentUri': segmentUri,
        'diskPath': diskPath,
        'sizeBytes': sizeBytes,
        'cachedAt': cachedAt.millisecondsSinceEpoch,
      };

  factory CachedSegment.fromJson(Map<String, dynamic> json) => CachedSegment(
        segmentUri: (json['segmentUri'] ?? '').toString(),
        diskPath: (json['diskPath'] ?? '').toString(),
        sizeBytes: _asInt(json['sizeBytes']),
        cachedAt: DateTime.fromMillisecondsSinceEpoch(
          _asInt(
            json['cachedAt'],
            fallback: DateTime.now().millisecondsSinceEpoch,
          ),
        ),
      );

  bool get isValid =>
      segmentUri.trim().isNotEmpty && diskPath.trim().isNotEmpty;
}

class VideoCacheEntry {
  final String docID;
  final String masterPlaylistUrl;
  final Map<String, CachedSegment> segments; // segmentUri -> CachedSegment
  Map<String, dynamic> cardData;
  int totalSegmentCount;
  int totalSizeBytes;
  DateTime lastAccessedAt;
  DateTime? lastUserInteractionAt;
  double watchProgress; // 0.0 - 1.0
  VideoCacheState state;

  static Map<String, CachedSegment> _cloneSegments(
    Map<String, CachedSegment> source,
  ) {
    return source.map(
      (key, value) => MapEntry(
        key,
        CachedSegment.fromJson(value.toJson()),
      ),
    );
  }

  static Map<String, dynamic> _cloneCardData(Map<String, dynamic> source) {
    return source.map(
      (key, value) => MapEntry(key, _cloneCardValue(value)),
    );
  }

  static dynamic _cloneCardValue(dynamic value) {
    if (value is Map<String, dynamic>) {
      return _cloneCardData(value);
    }
    if (value is Map) {
      return value.map(
        (key, nestedValue) => MapEntry(
          key.toString(),
          _cloneCardValue(nestedValue),
        ),
      );
    }
    if (value is List) {
      return value.map(_cloneCardValue).toList(growable: false);
    }
    return value;
  }

  VideoCacheEntry({
    required this.docID,
    required this.masterPlaylistUrl,
    Map<String, CachedSegment>? segments,
    Map<String, dynamic>? cardData,
    this.totalSegmentCount = 0,
    this.totalSizeBytes = 0,
    DateTime? lastAccessedAt,
    this.lastUserInteractionAt,
    this.watchProgress = 0.0,
    this.state = VideoCacheState.uncached,
  })  : segments = _cloneSegments(segments ?? const <String, CachedSegment>{}),
        cardData = _cloneCardData(cardData ?? const <String, dynamic>{}),
        lastAccessedAt = lastAccessedAt ?? DateTime.now();

  int get cachedSegmentCount => segments.length;
  bool get isFullyCached =>
      totalSegmentCount > 0 && cachedSegmentCount >= totalSegmentCount;

  Map<String, dynamic> toJson() => {
        'docID': docID,
        'masterPlaylistUrl': masterPlaylistUrl,
        'segments': segments.map((k, v) => MapEntry(k, v.toJson())),
        'cardData': _cloneCardData(cardData),
        'totalSegmentCount': totalSegmentCount,
        'totalSizeBytes': totalSizeBytes,
        'lastAccessedAt': lastAccessedAt.millisecondsSinceEpoch,
        'lastUserInteractionAt': lastUserInteractionAt?.millisecondsSinceEpoch,
        'watchProgress': watchProgress,
        'state': state.name,
      };

  factory VideoCacheEntry.fromJson(Map<String, dynamic> json) {
    final segmentsMap = <String, CachedSegment>{};
    final segmentsJson = (json['segments'] as Map?)?.cast<String, dynamic>() ??
        const <String, dynamic>{};
    for (final entry in segmentsJson.entries) {
      final rawValue = entry.value;
      if (rawValue is! Map) continue;
      final segment = CachedSegment.fromJson(
        Map<String, dynamic>.from(rawValue.cast<dynamic, dynamic>()),
      );
      if (!segment.isValid) continue;
      segmentsMap[entry.key] = segment;
    }

    return VideoCacheEntry(
      docID: (json['docID'] ?? '').toString(),
      masterPlaylistUrl: (json['masterPlaylistUrl'] ?? '').toString(),
      segments: segmentsMap,
      cardData: _cloneCardData(
        (json['cardData'] as Map?)?.cast<String, dynamic>() ??
            const <String, dynamic>{},
      ),
      totalSegmentCount: _asInt(json['totalSegmentCount']),
      totalSizeBytes: _asInt(json['totalSizeBytes']),
      lastAccessedAt: json['lastAccessedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              _asInt(
                json['lastAccessedAt'],
                fallback: DateTime.now().millisecondsSinceEpoch,
              ),
            )
          : DateTime.now(),
      lastUserInteractionAt: json['lastUserInteractionAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              _asInt(
                json['lastUserInteractionAt'],
                fallback: DateTime.now().millisecondsSinceEpoch,
              ),
            )
          : null,
      watchProgress: _asDouble(json['watchProgress']),
      state: VideoCacheState.values.firstWhere(
        (s) => s.name == (json['state'] ?? '').toString(),
        orElse: () => VideoCacheState.uncached,
      ),
    );
  }

  bool get isValid =>
      docID.trim().isNotEmpty && masterPlaylistUrl.trim().isNotEmpty;

  PostsModel? get cachedPostModel {
    if (cardData.isEmpty) return null;
    return PostsModel.fromMap(_cloneCardData(cardData), docID);
  }
}

class CacheIndex {
  final Map<String, VideoCacheEntry> entries; // docID -> entry
  int totalSizeBytes;

  /// 3 GB hard limit
  static const int maxSizeBytes = 3 * 1024 * 1024 * 1024;

  /// Soft limit = hard limit'in %70'i — eviction bu eşikte tetiklenir.
  static const int softLimitBytes = (maxSizeBytes * 70) ~/ 100;

  CacheIndex({
    Map<String, VideoCacheEntry>? entries,
    this.totalSizeBytes = 0,
  }) : entries = (entries ?? const <String, VideoCacheEntry>{}).map(
          (key, value) =>
              MapEntry(key, VideoCacheEntry.fromJson(value.toJson())),
        );

  Map<String, dynamic> toJson() => {
        'entries': entries.map((k, v) => MapEntry(k, v.toJson())),
        'totalSizeBytes': totalSizeBytes,
      };

  factory CacheIndex.fromJson(Map<String, dynamic> json) {
    final entriesMap = <String, VideoCacheEntry>{};
    final entriesJson = (json['entries'] as Map?)?.cast<String, dynamic>() ??
        const <String, dynamic>{};
    for (final entry in entriesJson.entries) {
      final rawValue = entry.value;
      if (rawValue is! Map) continue;
      final cacheEntry = VideoCacheEntry.fromJson(
        Map<String, dynamic>.from(rawValue.cast<dynamic, dynamic>()),
      );
      if (!cacheEntry.isValid) continue;
      entriesMap[entry.key] = cacheEntry;
    }
    return CacheIndex(
      entries: entriesMap,
      totalSizeBytes: _asInt(json['totalSizeBytes']),
    );
  }
}

int _asInt(dynamic value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value.trim()) ?? fallback;
  return fallback;
}

double _asDouble(dynamic value, {double fallback = 0.0}) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value.trim()) ?? fallback;
  return fallback;
}
