part of 'video_state_manager.dart';

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
