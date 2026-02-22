/// HLS segment cache data modelleri.

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
        segmentUri: json['segmentUri'] as String,
        diskPath: json['diskPath'] as String,
        sizeBytes: json['sizeBytes'] as int,
        cachedAt:
            DateTime.fromMillisecondsSinceEpoch(json['cachedAt'] as int),
      );
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

  VideoCacheEntry({
    required this.docID,
    required this.masterPlaylistUrl,
    Map<String, CachedSegment>? segments,
    this.totalSegmentCount = 0,
    this.totalSizeBytes = 0,
    DateTime? lastAccessedAt,
    this.watchProgress = 0.0,
    this.state = VideoCacheState.uncached,
  })  : segments = segments ?? {},
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
    final segmentsJson = json['segments'] as Map<String, dynamic>? ?? {};
    for (final entry in segmentsJson.entries) {
      segmentsMap[entry.key] =
          CachedSegment.fromJson(entry.value as Map<String, dynamic>);
    }

    return VideoCacheEntry(
      docID: json['docID'] as String,
      masterPlaylistUrl: json['masterPlaylistUrl'] as String,
      segments: segmentsMap,
      totalSegmentCount: json['totalSegmentCount'] as int? ?? 0,
      totalSizeBytes: json['totalSizeBytes'] as int? ?? 0,
      lastAccessedAt: json['lastAccessedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['lastAccessedAt'] as int)
          : DateTime.now(),
      watchProgress: (json['watchProgress'] as num?)?.toDouble() ?? 0.0,
      state: VideoCacheState.values.firstWhere(
        (s) => s.name == json['state'],
        orElse: () => VideoCacheState.uncached,
      ),
    );
  }
}

class CacheIndex {
  final Map<String, VideoCacheEntry> entries; // docID -> entry
  int totalSizeBytes;

  /// 3 GB hard limit
  static const int maxSizeBytes = 3 * 1024 * 1024 * 1024;

  /// 2.5 GB soft limit — eviction tetiklenir
  static const int softLimitBytes = 2684354560;

  CacheIndex({
    Map<String, VideoCacheEntry>? entries,
    this.totalSizeBytes = 0,
  }) : entries = entries ?? {};

  Map<String, dynamic> toJson() => {
        'entries': entries.map((k, v) => MapEntry(k, v.toJson())),
        'totalSizeBytes': totalSizeBytes,
      };

  factory CacheIndex.fromJson(Map<String, dynamic> json) {
    final entriesMap = <String, VideoCacheEntry>{};
    final entriesJson = json['entries'] as Map<String, dynamic>? ?? {};
    for (final entry in entriesJson.entries) {
      entriesMap[entry.key] =
          VideoCacheEntry.fromJson(entry.value as Map<String, dynamic>);
    }
    return CacheIndex(
      entries: entriesMap,
      totalSizeBytes: json['totalSizeBytes'] as int? ?? 0,
    );
  }
}
