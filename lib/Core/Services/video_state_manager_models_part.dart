part of 'video_state_manager.dart';

typedef FeedPlaybackBackstopSnapshotResolver = FeedPlaybackBackstopSnapshot?
    Function({
  required String? allowedKey,
  required String stoppingKey,
});

class FeedPlaybackBackstopSnapshot {
  const FeedPlaybackBackstopSnapshot({
    required this.allowedKey,
    required this.stoppingKey,
    required this.allowedDocId,
    required this.stoppingDocId,
    required this.centeredIndex,
    required this.centeredDocId,
    required this.allowedIndex,
    required this.stoppingIndex,
    required this.listCount,
  });

  final String allowedKey;
  final String stoppingKey;
  final String allowedDocId;
  final String stoppingDocId;
  final int centeredIndex;
  final String centeredDocId;
  final int allowedIndex;
  final int stoppingIndex;
  final int listCount;

  int? get allowedDistance => allowedIndex >= 0 && centeredIndex >= 0
      ? allowedIndex - centeredIndex
      : null;

  int? get stoppingDistance => stoppingIndex >= 0 && centeredIndex >= 0
      ? stoppingIndex - centeredIndex
      : null;
}

/// Video durum modeli
class VideoState {
  final Duration position;
  final bool isPlaying;
  final DateTime lastUpdated;

  VideoState({
    required this.position,
    required this.isPlaying,
    required this.lastUpdated,
  });

  VideoState copyWith({
    Duration? position,
    bool? isPlaying,
    DateTime? lastUpdated,
  }) {
    return VideoState(
      position: position ?? this.position,
      isPlaying: isPlaying ?? this.isPlaying,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}
