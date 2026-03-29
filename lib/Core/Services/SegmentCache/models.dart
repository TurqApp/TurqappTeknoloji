/// HLS segment cache data modelleri.
library;

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
  int totalSegmentCount;
  int totalSizeBytes;
  DateTime lastAccessedAt;
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

  VideoCacheEntry({
    required this.docID,
    required this.masterPlaylistUrl,
    Map<String, CachedSegment>? segments,
    this.totalSegmentCount = 0,
    this.totalSizeBytes = 0,
    DateTime? lastAccessedAt,
    this.watchProgress = 0.0,
    this.state = VideoCacheState.uncached,
  })  : segments = _cloneSegments(segments ?? const <String, CachedSegment>{}),
        lastAccessedAt = lastAccessedAt ?? DateTime.now();

  int get cachedSegmentCount => segments.length;
  bool get isFullyCached =>
      totalSegmentCount > 0 && cachedSegmentCount >= totalSegmentCount;

  Map<String, dynamic> toJson() => {
        'docID': docID,
        'masterPlaylistUrl': masterPlaylistUrl,
        'segments': segments.map((k, v) => MapEntry(k, v.toJson())),
        'totalSegmentCount': totalSegmentCount,
        'totalSizeBytes': totalSizeBytes,
        'lastAccessedAt': lastAccessedAt.millisecondsSinceEpoch,
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
      watchProgress: (json['watchProgress'] as num?)?.toDouble() ?? 0.0,
      state: VideoCacheState.values.firstWhere(
        (s) => s.name == (json['state'] ?? '').toString(),
        orElse: () => VideoCacheState.uncached,
      ),
    );
  }

  bool get isValid =>
      docID.trim().isNotEmpty && masterPlaylistUrl.trim().isNotEmpty;
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
